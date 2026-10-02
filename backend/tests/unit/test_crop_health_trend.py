from dataclasses import FrozenInstanceError
from decimal import Decimal
from types import SimpleNamespace
from uuid import UUID

import pytest

from app.core.errors import NotFoundException
from app.crop_health import (
    TREND_CHANGE_THRESHOLD,
    CropHealthTrend,
    calculate_ndvi_trend,
)
from app.services.crop_health_trend import CropHealthTrendService


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
    service = CropHealthTrendService.__new__(CropHealthTrendService)
    service.farmer_profile_repository = FakeProfileRepository(profile)
    service.repository = FakeCropHealthRepository(crop, history)
    return service


def _user():
    return SimpleNamespace(
        id=UUID("00000000-0000-0000-0000-000000000003")
    )


def _profile():
    return SimpleNamespace(id=PROFILE_ID)


def _crop():
    return SimpleNamespace(id=CROP_ID)


def _pair(ndvi_value):
    return SimpleNamespace(), SimpleNamespace(metric_value=ndvi_value)


def test_improving_trend():
    result = calculate_ndvi_trend(
        [Decimal("0.20"), Decimal("0.31"), Decimal("0.40")]
    )

    assert result == CropHealthTrend(
        direction="Improving",
        first_ndvi=Decimal("0.20"),
        latest_ndvi=Decimal("0.40"),
        change=Decimal("0.20"),
        observation_count=3,
    )


def test_declining_trend():
    result = calculate_ndvi_trend(
        [Decimal("0.80"), Decimal("0.71"), Decimal("0.60")]
    )

    assert result.direction == "Declining"
    assert result.change == Decimal("-0.20")


def test_stable_positive_change():
    result = calculate_ndvi_trend([Decimal("0.20"), Decimal("0.24")])

    assert result.direction == "Stable"
    assert result.change == Decimal("0.04")


def test_stable_negative_change():
    result = calculate_ndvi_trend([Decimal("0.60"), Decimal("0.56")])

    assert result.direction == "Stable"
    assert result.change == Decimal("-0.04")


def test_exact_positive_threshold_is_stable():
    result = calculate_ndvi_trend(
        [Decimal("0.20"), Decimal("0.25")]
    )

    assert TREND_CHANGE_THRESHOLD == Decimal("0.05")
    assert result.direction == "Stable"


def test_exact_negative_threshold_is_stable():
    result = calculate_ndvi_trend(
        [Decimal("0.25"), Decimal("0.20")]
    )

    assert result.direction == "Stable"


@pytest.mark.parametrize("values", [[], [Decimal("0.20")]])
def test_fewer_than_two_observations_raise_value_error(values):
    with pytest.raises(ValueError, match="At least two NDVI observations"):
        calculate_ndvi_trend(values)


def test_multiple_observations_use_first_and_latest_values():
    result = calculate_ndvi_trend(
        [Decimal("0.10"), Decimal("0.90"), Decimal("0.12")]
    )

    assert result.first_ndvi == Decimal("0.10")
    assert result.latest_ndvi == Decimal("0.12")
    assert result.change == Decimal("0.02")
    assert result.direction == "Stable"


def test_input_order_is_preserved():
    result = calculate_ndvi_trend(
        [Decimal("0.80"), Decimal("0.20"), Decimal("0.75")]
    )

    assert result.first_ndvi == Decimal("0.80")
    assert result.latest_ndvi == Decimal("0.75")
    assert result.direction == "Stable"


def test_decimal_precision_is_preserved():
    result = calculate_ndvi_trend(
        [Decimal("0.123456789"), Decimal("0.183456789")]
    )

    assert result.first_ndvi == Decimal("0.123456789")
    assert result.latest_ndvi == Decimal("0.183456789")
    assert result.change == Decimal("0.060000000")


def test_trend_result_is_immutable():
    result = calculate_ndvi_trend([Decimal("0.20"), Decimal("0.30")])

    with pytest.raises(FrozenInstanceError):
        result.direction = "Declining"


def test_improving_trend_uses_newest_first_history_chronologically():
    history = [_pair(Decimal("0.80")), _pair(Decimal("0.20"))]
    service = _service(_profile(), _crop(), history)

    result = service.get_crop_health_trend(_user(), CROP_ID)

    assert result.direction == "Improving"
    assert result.first_ndvi == Decimal("0.20")
    assert result.latest_ndvi == Decimal("0.80")
    assert result.change == Decimal("0.60")


def test_declining_trend_uses_oldest_and_newest_values():
    history = [_pair(Decimal("0.20")), _pair(Decimal("0.80"))]
    service = _service(_profile(), _crop(), history)

    result = service.get_crop_health_trend(_user(), CROP_ID)

    assert result.direction == "Declining"
    assert result.first_ndvi == Decimal("0.80")
    assert result.latest_ndvi == Decimal("0.20")


def test_stable_trend_from_persisted_history():
    history = [_pair(Decimal("0.24")), _pair(Decimal("0.20"))]
    service = _service(_profile(), _crop(), history)

    result = service.get_crop_health_trend(_user(), CROP_ID)

    assert result.direction == "Stable"
    assert result.change == Decimal("0.04")


def test_repository_values_are_reversed_without_sorting_or_modifying_history():
    history = [
        _pair(Decimal("0.70")),
        _pair(Decimal("0.50")),
        _pair(Decimal("0.10")),
    ]
    service = _service(_profile(), _crop(), history)

    result = service.get_crop_health_trend(_user(), CROP_ID)

    assert result.first_ndvi == Decimal("0.10")
    assert result.latest_ndvi == Decimal("0.70")
    assert [metric.metric_value for _, metric in history] == [
        Decimal("0.70"),
        Decimal("0.50"),
        Decimal("0.10"),
    ]


def test_fewer_than_two_history_records_propagates_value_error():
    service = _service(_profile(), _crop(), [_pair(Decimal("0.40"))])

    with pytest.raises(ValueError, match="At least two NDVI observations"):
        service.get_crop_health_trend(_user(), CROP_ID)


def test_empty_history_propagates_value_error():
    service = _service(_profile(), _crop(), [])

    with pytest.raises(ValueError, match="At least two NDVI observations"):
        service.get_crop_health_trend(_user(), CROP_ID)


def test_missing_farmer_profile_raises_not_found():
    with pytest.raises(NotFoundException, match="Crop not found."):
        _service(None, None, []).get_crop_health_trend(_user(), CROP_ID)


def test_inaccessible_crop_raises_not_found():
    with pytest.raises(NotFoundException, match="Crop not found."):
        _service(_profile(), None, []).get_crop_health_trend(
            _user(),
            CROP_ID,
        )


def test_repository_receives_crop_and_farmer_profile_ids():
    service = _service(
        _profile(),
        _crop(),
        [_pair(Decimal("0.70")), _pair(Decimal("0.20"))],
    )

    service.get_crop_health_trend(_user(), CROP_ID)

    assert service.repository.ownership_arguments == (CROP_ID, PROFILE_ID)
    assert service.repository.history_arguments == (CROP_ID, PROFILE_ID)
