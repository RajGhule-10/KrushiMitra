from decimal import Decimal

import pytest

from app.services.ndvi_classification import classify_ndvi


@pytest.mark.parametrize(
    ("mean_ndvi", "expected_status"),
    [
        ("-1.0", "Severe"),
        ("0.19", "Severe"),
        ("0.20", "Bad"),
        ("0.39", "Bad"),
        ("0.40", "Good"),
        ("0.59", "Good"),
        ("0.60", "Great"),
        ("1.0", "Great"),
    ],
)
def test_classifies_ndvi_boundary_values(mean_ndvi, expected_status):
    assert classify_ndvi(Decimal(mean_ndvi)) == expected_status
