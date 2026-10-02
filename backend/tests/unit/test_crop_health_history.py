from datetime import date
from decimal import Decimal
from types import SimpleNamespace
from uuid import UUID

import pytest

from app.core.errors import NotFoundException
from app.models.observation import CropObservation, HealthMetric
from app.schemas.crop_health import CropHealthHistoryResponse
from app.services.crop_health_history import CropHealthHistoryService


CROP_ID = UUID("00000000-0000-0000-0000-000000000001")
PROFILE_ID = UUID("00000000-0000-0000-0000-000000000002")


class FakeProfileRepository:
    def __init__(self, profile):
        self.profile = profile

    def get_by_user_id(self, user_id):
        return self.profile


class FakeCropHealthRepository:
    def __init__(self, crop, history):
        self.crop = crop
        self.history = history
        self.ownership_arguments = None
        self.history_arguments = None

    def get_crop_by_id_for_farmer(self, crop_id, farmer_profile_id):
        self.ownership_arguments = (crop_id, farmer_profile_id)
        return self.crop

    def get_health_history_for_crop(self, crop_id, farmer_profile_id):
        self.history_arguments = (crop_id, farmer_profile_id)
        return self.history


def _service(profile, crop, history):
    service = CropHealthHistoryService.__new__(CropHealthHistoryService)
    service.farmer_profile_repository = FakeProfileRepository(profile)
    service.repository = FakeCropHealthRepository(crop, history)
    return service


def _user():
    return SimpleNamespace(id=UUID("00000000-0000-0000-0000-000000000003"))


def _profile():
    return SimpleNamespace(id=PROFILE_ID)


def _crop():
    return SimpleNamespace(id=CROP_ID)


def _pair(observation_id, observation_date, ndvi_mean, status, cloud):
    observation = CropObservation(
        id=observation_id,
        crop_id=CROP_ID,
        observation_date=observation_date,
        data_source="sentinel-2",
        cloud_percentage=cloud,
    )
    metric = HealthMetric(
        observation_id=observation_id,
        metric_name="ndvi_mean",
        metric_value=ndvi_mean,
        health_status=status,
    )
    return observation, metric


def test_owned_crop_history_maps_multiple_records_and_arguments():
    history = [
        _pair(
            UUID("00000000-0000-0000-0000-000000000004"),
            date(2026, 10, 2),
            Decimal("0.750000"),
            "Great",
            Decimal("5.25"),
        ),
        _pair(
            UUID("00000000-0000-0000-0000-000000000005"),
            date(2026, 9, 2),
            Decimal("0.350000"),
            "Bad",
            None,
        ),
    ]
    service = _service(_profile(), _crop(), history)

    result = service.get_crop_health_history(_user(), CROP_ID)

    assert isinstance(result, CropHealthHistoryResponse)
    assert result.crop_id == CROP_ID
    assert result.history[0].ndvi_mean == Decimal("0.750000")
    assert result.history[0].health_status == "Great"
    assert result.history[0].cloud_percentage == Decimal("5.25")
    assert result.history[1].observation_date == date(2026, 9, 2)
    assert result.history[1].cloud_percentage is None
    assert service.repository.ownership_arguments == (CROP_ID, PROFILE_ID)
    assert service.repository.history_arguments == (CROP_ID, PROFILE_ID)


def test_empty_history_returns_empty_list():
    service = _service(_profile(), _crop(), [])

    result = service.get_crop_health_history(_user(), CROP_ID)

    assert result == CropHealthHistoryResponse(crop_id=CROP_ID, history=[])


def test_missing_farmer_profile_raises_not_found():
    with pytest.raises(NotFoundException, match="Crop not found."):
        _service(None, None, []).get_crop_health_history(_user(), CROP_ID)


def test_inaccessible_crop_raises_not_found():
    with pytest.raises(NotFoundException, match="Crop not found."):
        _service(_profile(), None, []).get_crop_health_history(_user(), CROP_ID)
