from datetime import date

from pydantic import BaseModel, Field


class SatelliteImage(BaseModel):
    """Provider-independent metadata for a satellite image result."""

    image_id: str
    acquisition_date: date
    cloud_percentage: float | None = Field(
        default=None,
        ge=0,
        le=100,
    )
    provider: str
    collection: str | None = None
