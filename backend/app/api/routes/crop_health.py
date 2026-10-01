from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.crop_health import CropHealthResponse
from app.services.crop_health import CropHealthService


router = APIRouter()


@router.get("/{crop_id}/health", response_model=CropHealthResponse)
def get_crop_health(
    crop_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CropHealthResponse:
    return CropHealthService(db).get_crop_health(current_user, crop_id)
