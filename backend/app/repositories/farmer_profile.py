from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import FarmerProfile


class FarmerProfileRepository:
    """Database access for farmer profiles."""

    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_user_id(self, user_id: UUID) -> FarmerProfile | None:
        statement = select(FarmerProfile).where(FarmerProfile.user_id == user_id)
        return self.db.scalar(statement)

    def update(
        self,
        profile: FarmerProfile,
        values: dict[str, object],
    ) -> FarmerProfile:
        for field, value in values.items():
            setattr(profile, field, value)
        return profile

    def commit(self) -> None:
        self.db.commit()

    def refresh(self, profile: FarmerProfile) -> None:
        self.db.refresh(profile)

    def rollback(self) -> None:
        self.db.rollback()
