from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.crop import Crop
from app.models.observation import CropObservation, HealthMetric


class CropObservationRepository:
    """Database access for crop observations and health metrics."""

    def __init__(self, db: Session) -> None:
        self.db = db

    def get_crop_by_id(self, crop_id: UUID) -> Crop | None:
        return self.db.scalar(select(Crop).where(Crop.id == crop_id))

    def create_observation(self, observation: CropObservation) -> CropObservation:
        self.db.add(observation)
        self.db.flush()
        return observation

    def create_health_metric(self, metric: HealthMetric) -> HealthMetric:
        self.db.add(metric)
        self.db.flush()
        return metric

    def get_observation_by_id(self, observation_id: UUID) -> CropObservation | None:
        return self.db.scalar(
            select(CropObservation).where(CropObservation.id == observation_id)
        )

    def get_observations_for_crop(self, crop_id: UUID) -> list[CropObservation]:
        statement = select(CropObservation).where(CropObservation.crop_id == crop_id)
        return list(self.db.scalars(statement))

    def get_health_metrics_for_observation(
        self,
        observation_id: UUID,
    ) -> list[HealthMetric]:
        statement = select(HealthMetric).where(
            HealthMetric.observation_id == observation_id
        )
        return list(self.db.scalars(statement))

    def commit(self) -> None:
        self.db.commit()

    def refresh(self, entity: CropObservation | HealthMetric) -> None:
        self.db.refresh(entity)

    def rollback(self) -> None:
        self.db.rollback()
