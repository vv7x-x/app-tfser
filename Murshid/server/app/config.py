import os
from pathlib import Path

# Base directories
BASE_DIR = Path(__file__).resolve().parent.parent
UPLOAD_DIR = BASE_DIR / "uploads"
DB_PATH = BASE_DIR / "murshid.db"

# App settings
DATABASE_URL = f"sqlite:///{DB_PATH}"
MAX_UPLOAD_BYTES = 100 * 1024 * 1024  # 100 MB

# Allowed content types for uploaded files
ALLOWED_CONTENT_PREFIXES = ("image/", "video/")

# Ensure directories exist at import time (safe if called multiple times)
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)