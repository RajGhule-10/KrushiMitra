from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class AdvisoryResponse(BaseModel):
    id: UUID
    crop_id: UUID
    observation_id: UUID
    title: str
    message: str
    severity: str
    priority: str
    category: str
    is_read: bool
    created_at: datetime
    expires_at: datetime | None


class CropAdvisoryResponse(BaseModel):
    crop_id: UUID
    advisory: AdvisoryResponse | None = None
