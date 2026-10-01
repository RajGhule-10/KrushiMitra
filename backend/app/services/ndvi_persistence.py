from decimal import Decimal, InvalidOperation
from uuid import UUID

from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.core.errors import NotFoundException
from app.models.observation import CropObservation, HealthMetric
from app.remote_sensing.exceptions import RemoteSensingProviderError
from app.remote_sensing.models import SatelliteImage
from app.repositories.crop_observation import CropObservationRepository


class NdviPersistenceService:
    """Persist a computed Sentinel-2 mean NDVI value for an existing crop."""

    def __init__(self, db: Session) -> None:
        self.repository = CropObservationRepository(db)

    def persist_mean_ndvi(
        self,
        crop_id: UUID,
        image: SatelliteImage,
        mean_ndvi: object,
    ) -> tuple[CropObservation, HealthMetric]:
        crop = self.repository.get_crop_by_id(crop_id)
        if crop is None:
            raise NotFoundException("Crop not found.")

        metric_value = _validate_mean_ndvi(mean_ndvi)
        cloud_percentage = (
            Decimal(str(image.cloud_percentage))
            if image.cloud_percentage is not None
            else None
        )
        observation = CropObservation(
            crop_id=crop.id,
            observation_date=image.acquisition_date,
            data_source="sentinel-2",
            cloud_percentage=cloud_percentage,
        )

        try:
            self.repository.create_observation(observation)
            metric = HealthMetric(
                observation_id=observation.id,
                metric_name="ndvi_mean",
                metric_value=metric_value,
                health_status=None,
            )
            self.repository.create_health_metric(metric)
            self.repository.commit()
            self.repository.refresh(observation)
            self.repository.refresh(metric)
        except SQLAlchemyError:
            self.repository.rollback()
            raise

        return observation, metric


def _validate_mean_ndvi(value: object) -> Decimal:
    if isinstance(value, bool) or not isinstance(value, (int, float, Decimal)):
        raise RemoteSensingProviderError(
            "Mean NDVI must be a finite numeric value between -1 and 1."
        )

    try:
        decimal_value = Decimal(str(value))
    except (InvalidOperation, ValueError) as error:
        raise RemoteSensingProviderError(
            "Mean NDVI must be a finite numeric value between -1 and 1."
        ) from error

    if not decimal_value.is_finite() or not Decimal("-1") <= decimal_value <= Decimal("1"):
        raise RemoteSensingProviderError(
            "Mean NDVI must be a finite numeric value between -1 and 1."
        )

    return decimal_value
