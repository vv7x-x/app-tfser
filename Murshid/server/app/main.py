import os
import secrets
from datetime import datetime
from pathlib import Path
from typing import List, Optional

from fastapi import FastAPI, File, UploadFile, Form, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from starlette import status

from sqlalchemy.orm import Session

from .config import UPLOAD_DIR, MAX_UPLOAD_BYTES, ALLOWED_CONTENT_PREFIXES
from .database import Base, engine, SessionLocal
from .models import Report
from .schemas import ReportOut

app = FastAPI(title="Murshid API", version="1.0.0")

# CORS (ضع قيودًا أدق في الإنتاج)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.on_event("startup")
def on_startup() -> None:
    # Ensure DB tables and upload directory exist
    Base.metadata.create_all(bind=engine)
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


def _save_upload_to_disk(upload: UploadFile) -> str:
    """Save uploaded file to disk under uploads/ with a safe unique name.

    Returns the relative file path (str) under server base, e.g. "uploads/<file>".
    Enforces MAX_UPLOAD_BYTES and allowed content prefixes.
    """
    content_type = upload.content_type or ""
    if not any(content_type.startswith(prefix) for prefix in ALLOWED_CONTENT_PREFIXES):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Unsupported media type. Only image/* or video/* allowed.")

    # Determine extension from original filename
    suffix = Path(upload.filename or "upload").suffix
    unique_name = f"{datetime.utcnow().strftime('%Y%m%dT%H%M%S')}_{secrets.token_hex(6)}{suffix}"
    destination = UPLOAD_DIR / unique_name

    total_bytes = 0
    with destination.open("wb") as out_file:
        while True:
            chunk = upload.file.read(1024 * 1024)  # 1MB chunks
            if not chunk:
                break
            total_bytes += len(chunk)
            if total_bytes > MAX_UPLOAD_BYTES:
                try:
                    destination.unlink(missing_ok=True)
                except Exception:
                    pass
                raise HTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, detail="File too large. Max 100MB")
            out_file.write(chunk)

    # Return a path like "uploads/<filename>"
    return str(Path("uploads") / unique_name)


@app.post("/report", response_model=ReportOut, status_code=status.HTTP_201_CREATED)
async def create_report(
    file: UploadFile = File(...),
    latitude: float = Form(...),
    longitude: float = Form(...),
    reported_at: Optional[str] = Form(None),
    db: Session = Depends(get_db),
):
    """استقبال البلاغ: ملف (صورة/فيديو) + إحداثيات + وقت البلاغ.

    - يحفظ الملف في uploads/
    - يسجل البيانات في SQLite
    """
    # If Content-Length header present, optional early check (best-effort)
    # Note: actual strict check is during streaming save
    try:
        saved_path = _save_upload_to_disk(file)
    finally:
        # Reset file pointer in case needed
        try:
            file.file.close()
        except Exception:
            pass

    media_type = "image" if (file.content_type or "").startswith("image/") else "video"

    # Parse reported_at if provided
    reported_dt: Optional[datetime] = None
    if reported_at:
        try:
            reported_dt = datetime.fromisoformat(reported_at)
        except Exception:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="reported_at must be ISO 8601 format")

    report = Report(
        file_path=saved_path,
        media_type=media_type,
        latitude=latitude,
        longitude=longitude,
        reported_at=reported_dt or datetime.utcnow(),
    )
    db.add(report)
    db.commit()
    db.refresh(report)

    return report


@app.get("/reports", response_model=List[ReportOut])
async def list_reports(db: Session = Depends(get_db)):
    """إرجاع كل البلاغات (مخصص للاستخدام الحكومي)."""
    reports = db.query(Report).order_by(Report.id.desc()).all()
    return reports