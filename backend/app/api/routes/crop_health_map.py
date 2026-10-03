from uuid import UUID

from fastapi import APIRouter, Depends, Path, Response
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.core.errors import BadRequestException
from app.database.session import get_db
from app.models.user import User
from app.remote_sensing.exceptions import RemoteSensingProviderError
from app.schemas.crop_health import (
    CropHealthMapResponse,
    CropHealthMapVisualization,
)
from app.services.crop_health_map import CropHealthMapService


router = APIRouter()


@router.get(
    "/{crop_id}/health/map",
    response_model=CropHealthMapResponse,
)
def get_crop_health_map(
    crop_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CropHealthMapResponse:
    try:
        result = CropHealthMapService(db).get_crop_health_map(
            current_user,
            crop_id,
        )
    except RemoteSensingProviderError as error:
        raise BadRequestException(str(error)) from error

    return CropHealthMapResponse(
        crop_id=result.crop_id,
        observation_date=result.observation_date,
        data_source=result.data_source,
        visualization=CropHealthMapVisualization(
            type="ndvi",
            min=result.visualization.minimum,
            max=result.visualization.maximum,
            palette=list(result.visualization.palette),
        ),
        tile_url_template=(
            f"/api/v1/crops/{crop_id}/health/map/tiles/{{z}}/{{x}}/{{y}}"
        ),
    )


@router.get(
    "/{crop_id}/health/map/tiles/{z}/{x}/{y}",
    response_class=Response,
)
def get_crop_health_map_tile(
    crop_id: UUID,
    z: int = Path(ge=0, le=22),
    x: int = Path(ge=0),
    y: int = Path(ge=0),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Response:
    if x >= 2**z or y >= 2**z:
        raise BadRequestException("Invalid map tile coordinates.")

    try:
        tile = CropHealthMapService(db).get_tile(
            current_user,
            crop_id,
            z,
            x,
            y,
        )
    except ValueError as error:
        raise BadRequestException(str(error)) from error
    except RemoteSensingProviderError as error:
        raise BadRequestException(str(error)) from error

    return Response(content=tile, media_type="image/png")
