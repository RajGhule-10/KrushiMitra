from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import FarmerProfile, User


class AuthRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_user_by_phone(
        self,
        phone_number: str,
    ) -> User | None:
        statement = select(User).where(User.phone_number == phone_number)

        return self.db.scalar(statement)

    def create_user(
        self,
        user: User,
    ) -> User:
        self.db.add(user)
        self.db.flush()
        return user

    def create_farmer_profile(
        self,
        profile: FarmerProfile,
    ) -> FarmerProfile:
        self.db.add(profile)
        self.db.flush()
        return profile

    def commit(self) -> None:
        self.db.commit()

    def rollback(self) -> None:
        self.db.rollback()
