from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.crop import Crop
from app.models.farm import Farm


class CropRepository:
    """Database access for crops belonging to farmer-owned farms."""

    def __init__(self, db: Session) -> None:
        self.db = db

    def create(self, crop: Crop) -> Crop:
        self.db.add(crop)
        self.db.flush()
        return crop

    def get_all_for_farm(self, farm_id: UUID) -> list[Crop]:
        statement = (
            select(Crop)
            .where(Crop.farm_id == farm_id)
            .order_by(Crop.created_at.desc(), Crop.id.desc())
        )
        return list(self.db.scalars(statement))

    def get_by_id_for_farmer(
        self,
        crop_id: UUID,
        farmer_profile_id: UUID,
    ) -> Crop | None:
        statement = (
            select(Crop)
            .join(Farm, Crop.farm_id == Farm.id)
            .where(
                Crop.id == crop_id,
                Farm.farmer_id == farmer_profile_id,
            )
        )
        return self.db.scalar(statement)

    def update(self, crop: Crop, values: dict[str, object]) -> Crop:
        for field, value in values.items():
            setattr(crop, field, value)
        return crop

    def commit(self) -> None:
        self.db.commit()

    def refresh(self, crop: Crop) -> None:
        self.db.refresh(crop)

    def rollback(self) -> None:
        self.db.rollback()
