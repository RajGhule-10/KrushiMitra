from uuid import UUID

from sqlalchemy.orm import Session

from app.core.errors import NotFoundException
from app.models.user import User
from app.repositories.advisory import AdvisoryRepository
from app.repositories.crop_health import CropHealthRepository
from app.repositories.farmer_profile import FarmerProfileRepository
from app.schemas.advisory import AdvisoryResponse, CropAdvisoryResponse


class AdvisoryService:
    """Read the latest persisted advisory for an owned crop."""

    def __init__(self, db: Session) -> None:
        self.repository = AdvisoryRepository(db)
        self.crop_health_repository = CropHealthRepository(db)
        self.farmer_profile_repository = FarmerProfileRepository(db)

    def get_latest_crop_advisory(
        self,
        current_user: User,
        crop_id: UUID,
    ) -> CropAdvisoryResponse:
        profile = self.farmer_profile_repository.get_by_user_id(current_user.id)
        if profile is None:
            raise NotFoundException("Crop not found.")

        crop = self.crop_health_repository.get_crop_by_id_for_farmer(
            crop_id,
            profile.id,
        )
        if crop is None:
            raise NotFoundException("Crop not found.")

        advisory = self.repository.get_latest_for_crop_for_farmer(
            crop_id,
            profile.id,
        )
        if advisory is None:
            return CropAdvisoryResponse(crop_id=crop_id)

        return CropAdvisoryResponse(
            crop_id=crop_id,
            advisory=AdvisoryResponse(
                id=advisory.id,
                crop_id=advisory.crop_id,
                observation_id=advisory.observation_id,
                title=advisory.title,
                message=advisory.message,
                severity=advisory.severity,
                priority=advisory.priority,
                category=advisory.category,
                is_read=advisory.is_read,
                created_at=advisory.created_at,
                expires_at=advisory.expires_at,
            ),
        )
