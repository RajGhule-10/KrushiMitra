from datetime import date
from uuid import uuid4

import pytest

from app.core.errors import NotFoundException
from app.models.crop import Crop
from app.models.observation import CropObservation, HealthMetric
from app.services.crop_advisory import CropAdvisoryService


class FakeProfileRepository:
    def __init__(self, profile):
        self.profile = profile

    def get_by_user_id(self, user_id):
        return self.profile


class FakeCropHealthRepository:
    def __init__(self, crop, observation=None, metric=None):
        self.crop = crop
        self.observation = observation
        self.metric = metric

    def get_crop_by_id_for_farmer(self, crop_id, farmer_profile_id):
        if self.crop is not None and self.crop.id == crop_id:
            return self.crop
        return None

    def get_latest_observation_for_crop(self, crop_id):
        return self.observation

    def get_ndvi_mean_metric(self, observation_id):
        return self.metric


def _service(profile, crop, observation=None, metric=None):
    service = CropAdvisoryService.__new__(CropAdvisoryService)
    service.farmer_profile_repository = FakeProfileRepository(profile)
    service.repository = FakeCropHealthRepository(crop, observation, metric)
    return service


def _user():
    user = type("UserStub", (), {})()
    user.id = uuid4()
    return user


def _profile():
    profile = type("ProfileStub", (), {})()
    profile.id = uuid4()
    return profile


def _crop():
    return Crop(id=uuid4(), farm_id=uuid4(), crop_name="Wheat", season="rabi")


def _observation(crop_id):
    return CropObservation(
        id=uuid4(),
        crop_id=crop_id,
        observation_date=date(2026, 10, 1),
        data_source="sentinel-2",
    )


@pytest.mark.parametrize(
    ("health_status", "priority"),
    [
        ("Great", "low"),
        ("Good", "low"),
        ("Bad", "medium"),
        ("Severe", "high"),
    ],
)
def test_generates_advisory_from_persisted_health_status(health_status, priority):
    user = _user()
    profile = _profile()
    crop = _crop()
    observation = _observation(crop.id)
    metric = HealthMetric(
        observation_id=observation.id,
        metric_name="ndvi_mean",
        health_status=health_status,
    )

    advisory = _service(
        profile,
        crop,
        observation,
        metric,
    ).get_crop_advisory(user, crop.id)

    assert advisory is not None
    assert advisory.status == health_status
    assert advisory.priority == priority


def test_no_observation_returns_none():
    user = _user()
    profile = _profile()
    crop = _crop()

    assert _service(profile, crop).get_crop_advisory(user, crop.id) is None


def test_no_ndvi_mean_metric_returns_none():
    user = _user()
    profile = _profile()
    crop = _crop()
    observation = _observation(crop.id)

    assert (
        _service(profile, crop, observation).get_crop_advisory(user, crop.id)
        is None
    )


def test_missing_health_status_returns_none():
    user = _user()
    profile = _profile()
    crop = _crop()
    observation = _observation(crop.id)
    metric = HealthMetric(
        observation_id=observation.id,
        metric_name="ndvi_mean",
        health_status=None,
    )

    assert (
        _service(profile, crop, observation, metric).get_crop_advisory(
            user,
            crop.id,
        )
        is None
    )


@pytest.mark.parametrize("missing_profile", [True, False])
def test_inaccessible_or_nonexistent_crop_raises_not_found(missing_profile):
    user = _user()
    profile = None if missing_profile else _profile()
    crop = None if not missing_profile else _crop()
    crop_id = crop.id if crop is not None else uuid4()

    with pytest.raises(NotFoundException, match="Crop not found."):
        _service(profile, crop).get_crop_advisory(user, crop_id)
