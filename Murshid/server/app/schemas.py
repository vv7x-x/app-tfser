from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict


class ReportOut(BaseModel):
    id: int
    file_path: str = Field(description="Relative path to the saved file under uploads/")
    media_type: str
    latitude: float
    longitude: float
    reported_at: datetime

    model_config = ConfigDict(from_attributes=True)