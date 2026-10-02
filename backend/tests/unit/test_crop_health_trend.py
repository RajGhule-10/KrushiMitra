from dataclasses import FrozenInstanceError
from decimal import Decimal

import pytest

from app.crop_health import (
    TREND_CHANGE_THRESHOLD,
    CropHealthTrend,
    calculate_ndvi_trend,
)


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
