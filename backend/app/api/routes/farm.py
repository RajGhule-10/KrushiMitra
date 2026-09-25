from uuid import UUID

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.farm import FarmCreateRequest, FarmResponse, FarmUpdateRequest
from app.services.farm import FarmService


router = APIRouter()


@router.post("", response_model=FarmResponse, status_code=status.HTTP_201_CREATED)
def create_farm(
    request: FarmCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FarmResponse:
    return FarmService(db).create_farm(current_user, request)


@router.get("", response_model=list[FarmResponse])
def list_farms(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[FarmResponse]:
    return FarmService(db).list_farms(current_user)


@router.get("/{farm_id}", response_model=FarmResponse)
def get_farm(
    farm_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FarmResponse:
    return FarmService(db).get_farm(current_user, farm_id)


@router.patch("/{farm_id}", response_model=FarmResponse)
def update_farm(
    farm_id: UUID,
    request: FarmUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FarmResponse:
    return FarmService(db).update_farm(current_user, farm_id, request)
