from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.crop import Crop
from app.models.farm import Farm
from app.models.observation import CropObservation, HealthMetric


class CropHealthRepository:
    """Read-only database access for persisted crop health data."""

    def __init__(self, db: Session) -> None:
        self.db = db

    def get_crop_by_id_for_farmer(
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

    def get_latest_observation_for_crop(
        self,
        crop_id: UUID,
    ) -> CropObservation | None:
        statement = (
            select(CropObservation)
            .where(CropObservation.crop_id == crop_id)
            .order_by(
                CropObservation.observation_date.desc(),
                CropObservation.created_at.desc(),
                CropObservation.id.desc(),
            )
            .limit(1)
        )
        return self.db.scalar(statement)

    def get_ndvi_mean_metric(
        self,
        observation_id: UUID,
    ) -> HealthMetric | None:
        statement = (
            select(HealthMetric)
            .where(
                HealthMetric.observation_id == observation_id,
                HealthMetric.metric_name == "ndvi_mean",
            )
            .order_by(HealthMetric.created_at.desc(), HealthMetric.id.desc())
            .limit(1)
        )
        return self.db.scalar(statement)
