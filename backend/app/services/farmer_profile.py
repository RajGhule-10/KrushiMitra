from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.core.errors import NotFoundException
from app.models.user import FarmerProfile, User
from app.repositories.farmer_profile import FarmerProfileRepository
from app.schemas.farmer import FarmerProfileUpdateRequest


class FarmerProfileService:
    """Business operations scoped to the authenticated farmer."""

    def __init__(self, db: Session) -> None:
        self.repository = FarmerProfileRepository(db)

    def get_profile(self, current_user: User) -> FarmerProfile:
        profile = self.repository.get_by_user_id(current_user.id)
        if profile is None:
            raise NotFoundException("Farmer profile not found.")
        return profile

    def update_profile(
        self,
        current_user: User,
        request: FarmerProfileUpdateRequest,
    ) -> FarmerProfile:
        profile = self.get_profile(current_user)
        values = request.model_dump(exclude_unset=True)

        self.repository.update(profile, values)

        try:
            self.repository.commit()
            self.repository.refresh(profile)
        except SQLAlchemyError:
            self.repository.rollback()
            raise

        return profile
