from uuid import UUID

from sqlalchemy.orm import Session

from app.core.errors import NotFoundException
from app.models.user import User
from app.repositories.crop_health import CropHealthRepository
from app.repositories.farmer_profile import FarmerProfileRepository
from app.schemas.crop_health import (
    CropHealthResponse,
    LatestCropHealthObservation,
)


class CropHealthService:
    """Read the latest persisted NDVI health result for an owned crop."""

    def __init__(self, db: Session) -> None:
        self.repository = CropHealthRepository(db)
        self.farmer_profile_repository = FarmerProfileRepository(db)

    def get_crop_health(self, current_user: User, crop_id: UUID) -> CropHealthResponse:
        profile = self.farmer_profile_repository.get_by_user_id(current_user.id)
        if profile is None:
            raise NotFoundException("Crop not found.")

        crop = self.repository.get_crop_by_id_for_farmer(crop_id, profile.id)
        if crop is None:
            raise NotFoundException("Crop not found.")

        observation = self.repository.get_latest_observation_for_crop(crop.id)
        if observation is None:
            return CropHealthResponse(crop_id=crop.id, crop_name=crop.crop_name)

        metric = self.repository.get_ndvi_mean_metric(observation.id)
        if metric is None:
            return CropHealthResponse(crop_id=crop.id, crop_name=crop.crop_name)

        return CropHealthResponse(
            crop_id=crop.id,
            crop_name=crop.crop_name,
            latest_observation=LatestCropHealthObservation(
                observation_date=observation.observation_date,
                data_source=observation.data_source,
                cloud_percentage=observation.cloud_percentage,
                ndvi_mean=metric.metric_value,
            ),
        )
