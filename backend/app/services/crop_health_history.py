from uuid import UUID

from sqlalchemy.orm import Session

from app.core.errors import NotFoundException
from app.models.user import User
from app.repositories.crop_health import CropHealthRepository
from app.repositories.farmer_profile import FarmerProfileRepository
from app.schemas.crop_health import (
    CropHealthHistoryItem,
    CropHealthHistoryResponse,
)


class CropHealthHistoryService:
    """Read persisted NDVI health history for an owned crop."""

    def __init__(self, db: Session) -> None:
        self.repository = CropHealthRepository(db)
        self.farmer_profile_repository = FarmerProfileRepository(db)

    def get_crop_health_history(
        self,
        current_user: User,
        crop_id: UUID,
    ) -> CropHealthHistoryResponse:
        profile = self.farmer_profile_repository.get_by_user_id(current_user.id)
        if profile is None:
            raise NotFoundException("Crop not found.")

        crop = self.repository.get_crop_by_id_for_farmer(crop_id, profile.id)
        if crop is None:
            raise NotFoundException("Crop not found.")

        history = [
            CropHealthHistoryItem(
                observation_date=observation.observation_date,
                data_source=observation.data_source,
                cloud_percentage=observation.cloud_percentage,
                ndvi_mean=metric.metric_value,
                health_status=metric.health_status,
            )
            for observation, metric in self.repository.get_health_history_for_crop(
                crop_id,
                profile.id,
            )
        ]
        return CropHealthHistoryResponse(crop_id=crop_id, history=history)
