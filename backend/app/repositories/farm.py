from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.farm import Farm


class FarmRepository:
    """Database access for farms owned by farmer profiles."""

    def __init__(self, db: Session) -> None:
        self.db = db

    def create(self, farm: Farm) -> Farm:
        self.db.add(farm)
        self.db.flush()
        return farm

    def get_all_for_farmer(self, farmer_profile_id: UUID) -> list[Farm]:
        statement = (
            select(Farm)
            .where(Farm.farmer_id == farmer_profile_id)
            .order_by(Farm.created_at.desc(), Farm.id.desc())
        )
        return list(self.db.scalars(statement))

    def get_by_id_for_farmer(
        self,
        farm_id: UUID,
        farmer_profile_id: UUID,
    ) -> Farm | None:
        statement = select(Farm).where(
            Farm.id == farm_id,
            Farm.farmer_id == farmer_profile_id,
        )
        return self.db.scalar(statement)

    def update(self, farm: Farm, values: dict[str, object]) -> Farm:
        for field, value in values.items():
            setattr(farm, field, value)
        return farm

    def commit(self) -> None:
        self.db.commit()

    def refresh(self, farm: Farm) -> None:
        self.db.refresh(farm)

    def rollback(self) -> None:
        self.db.rollback()
