from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.core.errors import BadRequestException
from app.database.session import get_db
from app.models.user import User
from app.schemas.crop_health import (
    CropHealthTrendDetails,
    CropHealthTrendResponse,
)
from app.services.crop_health_trend import CropHealthTrendService


router = APIRouter()


@router.get(
    "/{crop_id}/health/trend",
    response_model=CropHealthTrendResponse,
)
def get_crop_health_trend(
    crop_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CropHealthTrendResponse:
    try:
        trend = CropHealthTrendService(db).get_crop_health_trend(
            current_user,
            crop_id,
        )
    except ValueError as error:
        raise BadRequestException(str(error)) from error

    return CropHealthTrendResponse(
        crop_id=crop_id,
        trend=CropHealthTrendDetails(
            direction=trend.direction,
            first_ndvi=trend.first_ndvi,
            latest_ndvi=trend.latest_ndvi,
            change=trend.change,
            observation_count=trend.observation_count,
        ),
    )
