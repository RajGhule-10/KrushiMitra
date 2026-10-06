from uuid import UUID

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.crop import CropCreateRequest, CropResponse, CropUpdateRequest
from app.services.crop import CropService


router = APIRouter()


@router.post(
    "/farms/{farm_id}/crops",
    response_model=CropResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_crop(
    farm_id: UUID,
    request: CropCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CropResponse:
    return CropService(db).create_crop(current_user, farm_id, request)


@router.get("/farms/{farm_id}/crops", response_model=list[CropResponse])
def list_crops(
    farm_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[CropResponse]:
    return CropService(db).list_crops(current_user, farm_id)


@router.get("/crops/{crop_id}", response_model=CropResponse)
def get_crop(
    crop_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CropResponse:
    return CropService(db).get_crop(current_user, crop_id)


@router.patch("/crops/{crop_id}", response_model=CropResponse)
def update_crop(
    crop_id: UUID,
    request: CropUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CropResponse:
    return CropService(db).update_crop(current_user, crop_id, request)
