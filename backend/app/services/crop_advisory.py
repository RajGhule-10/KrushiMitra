from uuid import UUID

from sqlalchemy.orm import Session

from app.advisory import Advisory, generate_advisory
from app.core.errors import NotFoundException
from app.models.user import User
from app.repositories.crop_health import CropHealthRepository
from app.repositories.farmer_profile import FarmerProfileRepository


class CropAdvisoryService:
    """Generate an advisory from persisted health data for an owned crop."""

    def __init__(self, db: Session) -> None:
        self.repository = CropHealthRepository(db)
        self.farmer_profile_repository = FarmerProfileRepository(db)

    def get_crop_advisory(
        self,
        current_user: User,
        crop_id: UUID,
    ) -> Advisory | None:
        profile = self.farmer_profile_repository.get_by_user_id(current_user.id)
        if profile is None:
            raise NotFoundException("Crop not found.")

        crop = self.repository.get_crop_by_id_for_farmer(crop_id, profile.id)
        if crop is None:
            raise NotFoundException("Crop not found.")

        observation = self.repository.get_latest_observation_for_crop(crop.id)
        if observation is None:
            return None

        metric = self.repository.get_ndvi_mean_metric(observation.id)
        if metric is None or metric.health_status is None:
            return None

        return generate_advisory(metric.health_status)
