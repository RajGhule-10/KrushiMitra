from dataclasses import dataclass
from datetime import date
from typing import Any, Mapping
from uuid import UUID

from sqlalchemy.orm import Session

from app.core.errors import NotFoundException
from app.models.user import User
from app.remote_sensing.exceptions import (
    RemoteSensingAuthenticationError,
    RemoteSensingProviderError,
)
from app.remote_sensing.gee.ndvi import GeeNdviProcessor
from app.remote_sensing.gee.processor import GeeImageProcessor
from app.remote_sensing.gee.provider import GeeRemoteSensingProvider
from app.remote_sensing.gee.visualization import (
    GeeNdviVisualization,
    GeeNdviVisualizationProcessor,
)
from app.repositories.crop_health import CropHealthRepository
from app.repositories.farm_boundary import FarmBoundaryRepository
from app.repositories.farmer_profile import FarmerProfileRepository
from app.services.crop_health_analysis import (
    DEFAULT_LOOKBACK_DAYS,
    DEFAULT_MAX_CLOUD_PERCENTAGE,
    prepare_latest_ndvi,
)


@dataclass(frozen=True)
class CropHealthMapResult:
    crop_id: UUID
    observation_date: date
    data_source: str
    visualization: GeeNdviVisualization


class CropHealthMapService:
    """Create a read-only NDVI map contract for an owned crop."""

    def __init__(
        self,
        db: Session,
        *,
        provider: GeeRemoteSensingProvider | None = None,
        image_processor: GeeImageProcessor | None = None,
        ndvi_processor: GeeNdviProcessor | None = None,
        visualization_processor: GeeNdviVisualizationProcessor | None = None,
    ) -> None:
        self.crop_health_repository = CropHealthRepository(db)
        self.farmer_profile_repository = FarmerProfileRepository(db)
        self.farm_boundary_repository = FarmBoundaryRepository(db)
        self.provider = provider or GeeRemoteSensingProvider()
        self.image_processor = image_processor or GeeImageProcessor()
        self.ndvi_processor = ndvi_processor or GeeNdviProcessor()
        self.visualization_processor = (
            visualization_processor or GeeNdviVisualizationProcessor()
        )

    def get_crop_health_map(
        self,
        current_user: User,
        crop_id: UUID,
        analysis_date: date | None = None,
    ) -> CropHealthMapResult:
        crop, geometry = self._get_crop_geometry(current_user, crop_id)
        image, ndvi_result = prepare_latest_ndvi(
            provider=self.provider,
            image_processor=self.image_processor,
            ndvi_processor=self.ndvi_processor,
            geometry=geometry,
            analysis_date=analysis_date,
        )
        visualization = self.visualization_processor.create(
            ndvi_result.ndvi_image,
        )
        return CropHealthMapResult(
            crop_id=crop.id,
            observation_date=image.acquisition_date,
            data_source="sentinel-2",
            visualization=visualization,
        )

    def get_tile(
        self,
        current_user: User,
        crop_id: UUID,
        z: int,
        x: int,
        y: int,
        analysis_date: date | None = None,
    ) -> bytes:
        if z < 0 or z > 22 or x < 0 or y < 0 or x >= 2**z or y >= 2**z:
            raise ValueError("Invalid map tile coordinates.")

        result = self.get_crop_health_map(
            current_user,
            crop_id,
            analysis_date,
        )
        try:
            tile = result.visualization.tile_fetcher.fetch_tile(x, y, z)
        except Exception as error:
            if _looks_like_authentication_error(error):
                raise RemoteSensingAuthenticationError(
                    "Google Earth Engine authentication failed while fetching a tile."
                ) from error
            raise RemoteSensingProviderError(
                "Google Earth Engine tile fetch failed."
            ) from error

        if not isinstance(tile, bytes):
            raise RemoteSensingProviderError(
                "Google Earth Engine returned invalid tile data."
            )
        return tile

    def _get_crop_geometry(
        self,
        current_user: User,
        crop_id: UUID,
    ) -> tuple[Any, Mapping[str, Any]]:
        profile = self.farmer_profile_repository.get_by_user_id(current_user.id)
        if profile is None:
            raise NotFoundException("Crop not found.")

        crop = self.crop_health_repository.get_crop_by_id_for_farmer(
            crop_id,
            profile.id,
        )
        if crop is None:
            raise NotFoundException("Crop not found.")

        boundary = self.farm_boundary_repository.get_by_farm_id(crop.farm_id)
        if boundary is None:
            raise NotFoundException("Farm boundary not found.")

        geometry = self.farm_boundary_repository.get_geometry_as_geojson(boundary)
        return crop, geometry


def _looks_like_authentication_error(error: Exception) -> bool:
    text = f"{type(error).__name__} {error}".lower()
    return any(
        term in text
        for term in ("auth", "credential", "permission", "unauthorized", "forbidden")
    )
