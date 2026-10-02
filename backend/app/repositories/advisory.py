from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.advisory import Advisory
from app.models.crop import Crop
from app.models.farm import Farm


class AdvisoryRepository:
    """Database access for persisted crop advisories."""

    def __init__(self, db: Session) -> None:
        self.db = db

    def create(self, advisory: Advisory) -> Advisory:
        self.db.add(advisory)
        self.db.flush()
        return advisory

    def commit(self) -> None:
        self.db.commit()

    def refresh(self, advisory: Advisory) -> None:
        self.db.refresh(advisory)

    def rollback(self) -> None:
        self.db.rollback()

    def get_latest_for_crop_for_farmer(
        self,
        crop_id: UUID,
        farmer_profile_id: UUID,
    ) -> Advisory | None:
        statement = (
            select(Advisory)
            .join(Crop, Advisory.crop_id == Crop.id)
            .join(Farm, Crop.farm_id == Farm.id)
            .where(
                Advisory.crop_id == crop_id,
                Farm.farmer_id == farmer_profile_id,
            )
            .order_by(
                Advisory.created_at.desc(),
                Advisory.id.desc(),
            )
            .limit(1)
        )
        return self.db.scalar(statement)
