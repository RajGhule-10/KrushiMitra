from datetime import date
from decimal import Decimal
from uuid import uuid4

import pytest
from sqlalchemy.exc import SQLAlchemyError

from app.models.crop import Crop
from app.models.farm import Farm
from app.models.user import FarmerProfile, User
from app.remote_sensing.models import SatelliteImage
from app.repositories.crop_observation import CropObservationRepository
from app.services.ndvi_persistence import NdviPersistenceService


def _create_crop(db_session) -> Crop:
    user = User(id=uuid4(), phone_number=f"94{uuid4().int % 10**8:08d}")
    profile = FarmerProfile(id=uuid4(), user_id=user.id, full_name="NDVI Farmer")
    farm = Farm(id=uuid4(), farmer_id=profile.id, name="NDVI Farm")
    crop = Crop(
        id=uuid4(),
        farm_id=farm.id,
        crop_name="Wheat",
        season="rabi",
    )
    db_session.add_all([user, profile, farm, crop])
    db_session.commit()
    return crop


def _image(cloud_percentage: float | None = 8.25) -> SatelliteImage:
    return SatelliteImage(
        image_id="S2A/integration-image",
        acquisition_date=date(2026, 10, 1),
        cloud_percentage=cloud_percentage,
        provider="google_earth_engine",
    )


def test_ndvi_persistence_creates_related_observation_and_metric(db_session):
    crop = _create_crop(db_session)

    observation, metric = NdviPersistenceService(db_session).persist_mean_ndvi(
        crop.id,
        _image(),
        0.42,
    )
    repository = CropObservationRepository(db_session)
    persisted_observation = repository.get_observation_by_id(observation.id)
    persisted_metrics = repository.get_health_metrics_for_observation(observation.id)

    assert persisted_observation is not None
    assert persisted_observation.crop_id == crop.id
    assert persisted_observation.observation_date == date(2026, 10, 1)
    assert persisted_observation.data_source == "sentinel-2"
    assert persisted_observation.cloud_percentage == Decimal("8.25")
    assert persisted_metrics == [metric]
    assert metric.observation_id == observation.id
    assert metric.metric_name == "ndvi_mean"
    assert metric.metric_value == Decimal("0.420000")
    assert metric.health_status == "Good"
    assert metric.observation.crop_id == crop.id


def test_ndvi_persistence_allows_null_cloud_percentage(db_session):
    crop = _create_crop(db_session)

    observation, metric = NdviPersistenceService(db_session).persist_mean_ndvi(
        crop.id,
        _image(cloud_percentage=None),
        -0.1,
    )

    assert observation.cloud_percentage is None
    assert metric.metric_value == Decimal("-0.100000")


def test_metric_failure_rolls_back_observation_insert(db_session, monkeypatch):
    crop = _create_crop(db_session)
    service = NdviPersistenceService(db_session)

    def raise_metric_failure(*args, **kwargs):
        raise SQLAlchemyError("metric insert failed")

    monkeypatch.setattr(service.repository, "create_health_metric", raise_metric_failure)

    with pytest.raises(SQLAlchemyError, match="metric insert failed"):
        service.persist_mean_ndvi(crop.id, _image(), 0.42)

    assert service.repository.get_observations_for_crop(crop.id) == []
