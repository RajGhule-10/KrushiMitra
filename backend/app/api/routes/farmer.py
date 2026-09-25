from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.farmer import FarmerProfileResponse, FarmerProfileUpdateRequest
from app.services.farmer_profile import FarmerProfileService


router = APIRouter()


@router.get("/profile", response_model=FarmerProfileResponse)
def get_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FarmerProfileResponse:
    return FarmerProfileService(db).get_profile(current_user)


@router.patch("/profile", response_model=FarmerProfileResponse)
def update_profile(
    request: FarmerProfileUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FarmerProfileResponse:
    return FarmerProfileService(db).update_profile(current_user, request)
