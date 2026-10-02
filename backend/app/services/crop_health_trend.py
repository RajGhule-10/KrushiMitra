from uuid import UUID

from sqlalchemy.orm import Session

from app.core.errors import NotFoundException
from app.crop_health import CropHealthTrend, calculate_ndvi_trend
from app.models.user import User
from app.repositories.crop_health import CropHealthRepository
from app.repositories.farmer_profile import FarmerProfileRepository


class CropHealthTrendService:
    """Calculate the NDVI trend for an owned crop."""

    def __init__(self, db: Session) -> None:
        self.repository = CropHealthRepository(db)
        self.farmer_profile_repository = FarmerProfileRepository(db)

    def get_crop_health_trend(
        self,
        current_user: User,
        crop_id: UUID,
    ) -> CropHealthTrend:
        profile = self.farmer_profile_repository.get_by_user_id(current_user.id)
        if profile is None:
            raise NotFoundException("Crop not found.")

        crop = self.repository.get_crop_by_id_for_farmer(crop_id, profile.id)
        if crop is None:
            raise NotFoundException("Crop not found.")

        history = self.repository.get_health_history_for_crop(
            crop_id,
            profile.id,
        )
        ndvi_values = [
            metric.metric_value for _, metric in reversed(history)
        ]
        return calculate_ndvi_trend(ndvi_values)
