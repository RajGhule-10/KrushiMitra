from datetime import datetime, timezone
from uuid import uuid4

import pytest

from app.core.errors import NotFoundException
from app.models.advisory import Advisory
from app.schemas.advisory import CropAdvisoryResponse
from app.services.advisory import AdvisoryService


class FakeProfileRepository:
    def __init__(self, profile):
        self.profile = profile

    def get_by_user_id(self, user_id):
        return self.profile


class FakeAdvisoryRepository:
    def __init__(self, advisory):
        self.advisory = advisory
        self.arguments = None

    def get_latest_for_crop_for_farmer(self, crop_id, farmer_profile_id):
        self.arguments = (crop_id, farmer_profile_id)
        return self.advisory


class FakeCropHealthRepository:
    def __init__(self, crop):
        self.crop = crop

    def get_crop_by_id_for_farmer(self, crop_id, farmer_profile_id):
        if self.crop is not None and self.crop.id == crop_id:
            return self.crop
        return None


def _service(profile, advisory, crop_id=None):
    service = AdvisoryService.__new__(AdvisoryService)
    service.farmer_profile_repository = FakeProfileRepository(profile)
    service.repository = FakeAdvisoryRepository(advisory)
    crop = type("CropStub", (), {})()
    crop.id = crop_id
    service.crop_health_repository = FakeCropHealthRepository(
        crop if crop_id is not None else None
    )
    return service


def _user():
    user = type("UserStub", (), {})()
    user.id = uuid4()
    return user


def _profile():
    profile = type("ProfileStub", (), {})()
    profile.id = uuid4()
    return profile


def _advisory(crop_id):
    return Advisory(
        id=uuid4(),
        farm_id=uuid4(),
        crop_id=crop_id,
        observation_id=uuid4(),
        title="Possible crop stress detected",
        message="Inspect the field.",
        severity="Bad",
        priority="medium",
        category="crop_health",
        is_read=False,
        created_at=datetime(2026, 10, 2, tzinfo=timezone.utc),
        expires_at=None,
    )


def test_existing_advisory_maps_to_response():
    user = _user()
    profile = _profile()
    crop_id = uuid4()
    advisory = _advisory(crop_id)

    result = _service(profile, advisory, crop_id).get_latest_crop_advisory(
        user,
        crop_id,
    )

    assert isinstance(result, CropAdvisoryResponse)
    assert result.crop_id == crop_id
    assert result.advisory is not None
    assert result.advisory.id == advisory.id
    assert result.advisory.observation_id == advisory.observation_id
    assert result.advisory.title == advisory.title
    assert result.advisory.message == advisory.message
    assert result.advisory.severity == advisory.severity
    assert result.advisory.priority == advisory.priority
    assert result.advisory.category == advisory.category
    assert result.advisory.is_read is False
    assert result.advisory.created_at == advisory.created_at
    assert result.advisory.expires_at is None


def test_no_advisory_returns_null_advisory():
    user = _user()
    profile = _profile()
    crop_id = uuid4()

    result = _service(profile, None, crop_id).get_latest_crop_advisory(
        user,
        crop_id,
    )

    assert result == CropAdvisoryResponse(crop_id=crop_id)


def test_missing_farmer_profile_raises_not_found():
    with pytest.raises(NotFoundException, match="Crop not found."):
        _service(None, None).get_latest_crop_advisory(_user(), uuid4())


def test_inaccessible_crop_raises_not_found():
    user = _user()
    profile = _profile()
    crop_id = uuid4()

    with pytest.raises(NotFoundException, match="Crop not found."):
        _service(profile, None, uuid4()).get_latest_crop_advisory(user, crop_id)
