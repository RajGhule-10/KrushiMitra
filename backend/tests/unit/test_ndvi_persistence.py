from datetime import date
from decimal import Decimal
from uuid import uuid4

import pytest
from sqlalchemy.exc import SQLAlchemyError

from app.core.errors import NotFoundException
from app.models.crop import Crop
from app.models.observation import CropObservation, HealthMetric
from app.remote_sensing.exceptions import RemoteSensingProviderError
from app.remote_sensing.models import SatelliteImage
from app.services.ndvi_persistence import NdviPersistenceService


class FakeRepository:
    def __init__(self, crop: Crop | None) -> None:
        self.crop = crop
        self.observation: CropObservation | None = None
        self.metric: HealthMetric | None = None
        self.committed = False
        self.rolled_back = False

    def get_crop_by_id(self, crop_id):
        return self.crop if self.crop and self.crop.id == crop_id else None

    def create_observation(self, observation: CropObservation) -> CropObservation:
        observation.id = uuid4()
        self.observation = observation
        return observation

    def create_health_metric(self, metric: HealthMetric) -> HealthMetric:
        metric.id = uuid4()
        self.metric = metric
        return metric

    def commit(self) -> None:
        self.committed = True

    def refresh(self, entity) -> None:
        return None

    def rollback(self) -> None:
        self.rolled_back = True


class MetricFailureRepository(FakeRepository):
    def create_health_metric(self, metric: HealthMetric) -> HealthMetric:
        raise SQLAlchemyError("metric insert failed")


def _crop() -> Crop:
    return Crop(id=uuid4(), farm_id=uuid4(), crop_name="Wheat", season="rabi")


def _image(cloud_percentage: float | None = 12.5) -> SatelliteImage:
    return SatelliteImage(
        image_id="S2A/test-image",
        acquisition_date=date(2026, 10, 1),
        cloud_percentage=cloud_percentage,
        provider="google_earth_engine",
    )


def _service(repository: FakeRepository) -> NdviPersistenceService:
    service = NdviPersistenceService.__new__(NdviPersistenceService)
    service.repository = repository
    return service


def test_persists_observation_and_mean_ndvi_metric():
    crop = _crop()
    repository = FakeRepository(crop)

    observation, metric = _service(repository).persist_mean_ndvi(
        crop.id,
        _image(),
        0.42,
    )

    assert repository.committed is True
    assert observation.crop_id == crop.id
    assert observation.observation_date == date(2026, 10, 1)
    assert observation.data_source == "sentinel-2"
    assert observation.cloud_percentage == Decimal("12.5")
    assert metric.observation_id == observation.id
    assert metric.metric_name == "ndvi_mean"
    assert metric.metric_value == Decimal("0.42")
    assert metric.health_status is None


def test_missing_crop_is_rejected():
    with pytest.raises(NotFoundException, match="Crop not found"):
        _service(FakeRepository(None)).persist_mean_ndvi(uuid4(), _image(), 0.42)


@pytest.mark.parametrize(
    "mean_ndvi",
    [True, "0.42", float("nan"), float("inf"), -1.01, 1.01],
)
def test_invalid_mean_ndvi_is_rejected(mean_ndvi):
    crop = _crop()
    repository = FakeRepository(crop)

    with pytest.raises(RemoteSensingProviderError, match="Mean NDVI"):
        _service(repository).persist_mean_ndvi(crop.id, _image(), mean_ndvi)

    assert repository.observation is None
    assert repository.committed is False


def test_null_cloud_percentage_is_preserved():
    crop = _crop()
    repository = FakeRepository(crop)

    observation, _ = _service(repository).persist_mean_ndvi(
        crop.id,
        _image(cloud_percentage=None),
        Decimal("-0.25"),
    )

    assert observation.cloud_percentage is None


def test_metric_persistence_failure_rolls_back_transaction():
    crop = _crop()
    repository = MetricFailureRepository(crop)

    with pytest.raises(SQLAlchemyError, match="metric insert failed"):
        _service(repository).persist_mean_ndvi(crop.id, _image(), 0.42)

    assert repository.observation is not None
    assert repository.committed is False
    assert repository.rolled_back is True
