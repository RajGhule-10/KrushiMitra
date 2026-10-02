from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.advisory import CropAdvisoryResponse
from app.services.advisory import AdvisoryService


router = APIRouter()


@router.get("/{crop_id}/advisory", response_model=CropAdvisoryResponse)
def get_crop_advisory(
    crop_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CropAdvisoryResponse:
    return AdvisoryService(db).get_latest_crop_advisory(current_user, crop_id)
