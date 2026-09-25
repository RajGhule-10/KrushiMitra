from uuid import UUID

from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.core.errors import NotFoundException
from app.models.farm import Farm
from app.models.user import FarmerProfile, User
from app.repositories.farm import FarmRepository
from app.repositories.farmer_profile import FarmerProfileRepository
from app.schemas.farm import FarmCreateRequest, FarmUpdateRequest


class FarmService:
    """Farm operations scoped to the authenticated farmer."""

    def __init__(self, db: Session) -> None:
        self.repository = FarmRepository(db)
        self.farmer_profile_repository = FarmerProfileRepository(db)

    def create_farm(self, current_user: User, request: FarmCreateRequest) -> Farm:
        profile = self._get_farmer_profile(current_user)
        farm = Farm(farmer_id=profile.id, **request.model_dump())
        self.repository.create(farm)
        self._commit_and_refresh(farm)
        return farm

    def list_farms(self, current_user: User) -> list[Farm]:
        profile = self._get_farmer_profile(current_user)
        return self.repository.get_all_for_farmer(profile.id)

    def get_farm(self, current_user: User, farm_id: UUID) -> Farm:
        profile = self._get_farmer_profile(current_user)
        return self._get_owned_farm(farm_id, profile)

    def update_farm(
        self,
        current_user: User,
        farm_id: UUID,
        request: FarmUpdateRequest,
    ) -> Farm:
        profile = self._get_farmer_profile(current_user)
        farm = self._get_owned_farm(farm_id, profile)
        self.repository.update(farm, request.model_dump(exclude_unset=True))
        self._commit_and_refresh(farm)
        return farm

    def _get_farmer_profile(self, current_user: User) -> FarmerProfile:
        profile = self.farmer_profile_repository.get_by_user_id(current_user.id)
        if profile is None:
            raise NotFoundException("Farmer profile not found.")
        return profile

    def _get_owned_farm(self, farm_id: UUID, profile: FarmerProfile) -> Farm:
        farm = self.repository.get_by_id_for_farmer(farm_id, profile.id)
        if farm is None:
            raise NotFoundException("Farm not found.")
        return farm

    def _commit_and_refresh(self, farm: Farm) -> None:
        try:
            self.repository.commit()
            self.repository.refresh(farm)
        except SQLAlchemyError:
            self.repository.rollback()
            raise
