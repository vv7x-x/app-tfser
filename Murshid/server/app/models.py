from sqlalchemy import Column, Integer, String, Float, DateTime
from sqlalchemy.sql import func

from .database import Base


class Report(Base):
    __tablename__ = "reports"

    id = Column(Integer, primary_key=True, index=True)
    file_path = Column(String, nullable=False)
    media_type = Column(String, nullable=False)  # image or video (derived from content-type)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    reported_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)