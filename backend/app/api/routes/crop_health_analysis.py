from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.database.session import get_db
from app.models.user import User
from app.schemas.crop_health import (
    CropHealthAnalysisAdvisoryResponse,
    CropHealthAnalysisHealthResponse,
    CropHealthAnalysisObservationResponse,
    CropHealthAnalysisResponse,
)
from app.services.crop_health_analysis import CropHealthAnalysisService


router = APIRouter()


@router.post(
    "/{crop_id}/analyze",
    response_model=CropHealthAnalysisResponse,
)
def analyze_crop_health(
    crop_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CropHealthAnalysisResponse:
    result = CropHealthAnalysisService(db).analyze_crop_health(
        current_user,
        crop_id,
    )
    return CropHealthAnalysisResponse(
        crop_id=result.crop_id,
        observation=CropHealthAnalysisObservationResponse(
            observation_date=result.observation.observation_date,
            data_source=result.observation.data_source,
            cloud_percentage=result.observation.cloud_percentage,
        ),
        health=CropHealthAnalysisHealthResponse(
            metric=result.metric.metric_name,
            value=result.metric.metric_value,
            status=result.metric.health_status,
        ),
        advisory=CropHealthAnalysisAdvisoryResponse(
            id=result.advisory.id,
            title=result.advisory.title,
            message=result.advisory.message,
            severity=result.advisory.severity,
            priority=result.advisory.priority,
            category=result.advisory.category,
        ),
    )
