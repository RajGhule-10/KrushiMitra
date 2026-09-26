from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.farm_boundary import FarmBoundaryResponse, GeometryRequest
from app.services.farm_boundary import FarmBoundaryService


router = APIRouter()


@router.put("/{farm_id}/boundary", response_model=FarmBoundaryResponse)
def put_boundary(
    farm_id: UUID,
    geometry: GeometryRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FarmBoundaryResponse:
    return FarmBoundaryService(db).put_boundary(current_user, farm_id, geometry)


@router.get("/{farm_id}/boundary", response_model=FarmBoundaryResponse)
def get_boundary(
    farm_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FarmBoundaryResponse:
    return FarmBoundaryService(db).get_boundary(current_user, farm_id)
