from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.crop_health import CropHealthHistoryResponse
from app.services.crop_health_history import CropHealthHistoryService


router = APIRouter()


@router.get(
    "/{crop_id}/health/history",
    response_model=CropHealthHistoryResponse,
)
def get_crop_health_history(
    crop_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CropHealthHistoryResponse:
    return CropHealthHistoryService(db).get_crop_health_history(
        current_user,
        crop_id,
    )
