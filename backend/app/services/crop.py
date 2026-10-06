from uuid import UUID

from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.core.errors import NotFoundException
from app.models.crop import Crop
from app.models.farm import Farm
from app.models.user import FarmerProfile, User
from app.repositories.crop import CropRepository
from app.repositories.farm import FarmRepository
from app.repositories.farmer_profile import FarmerProfileRepository
from app.schemas.crop import CropCreateRequest, CropUpdateRequest


class CropService:
    """Crop operations scoped to the authenticated farmer's farms."""

    def __init__(self, db: Session) -> None:
        self.repository = CropRepository(db)
        self.farm_repository = FarmRepository(db)
        self.farmer_profile_repository = FarmerProfileRepository(db)

    def create_crop(
        self,
        current_user: User,
        farm_id: UUID,
        request: CropCreateRequest,
    ) -> Crop:
        profile = self._get_farmer_profile(current_user)
        farm = self._get_owned_farm(farm_id, profile)
        crop = Crop(farm_id=farm.id, **request.model_dump())
        self.repository.create(crop)
        self._commit_and_refresh(crop)
        return crop

    def list_crops(self, current_user: User, farm_id: UUID) -> list[Crop]:
        profile = self._get_farmer_profile(current_user)
        farm = self._get_owned_farm(farm_id, profile)
        return self.repository.get_all_for_farm(farm.id)

    def get_crop(self, current_user: User, crop_id: UUID) -> Crop:
        profile = self._get_farmer_profile(current_user)
        crop = self.repository.get_by_id_for_farmer(crop_id, profile.id)
        if crop is None:
            raise NotFoundException("Crop not found.")
        return crop

    def update_crop(
        self,
        current_user: User,
        crop_id: UUID,
        request: CropUpdateRequest,
    ) -> Crop:
        profile = self._get_farmer_profile(current_user)
        crop = self.repository.get_by_id_for_farmer(crop_id, profile.id)
        if crop is None:
            raise NotFoundException("Crop not found.")
        self.repository.update(crop, request.model_dump(exclude_unset=True))
        self._commit_and_refresh(crop)
        return crop

    def _get_farmer_profile(self, current_user: User) -> FarmerProfile:
        profile = self.farmer_profile_repository.get_by_user_id(current_user.id)
        if profile is None:
            raise NotFoundException("Farmer profile not found.")
        return profile

    def _get_owned_farm(
        self,
        farm_id: UUID,
        profile: FarmerProfile,
    ) -> Farm:
        farm = self.farm_repository.get_by_id_for_farmer(farm_id, profile.id)
        if farm is None:
            raise NotFoundException("Farm not found.")
        return farm

    def _commit_and_refresh(self, crop: Crop) -> None:
        try:
            self.repository.commit()
            self.repository.refresh(crop)
        except SQLAlchemyError:
            self.repository.rollback()
            raise
