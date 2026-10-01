from decimal import Decimal
from typing import Literal

NDVIHealthStatus = Literal["Severe", "Bad", "Good", "Great"]

_BAD_THRESHOLD = Decimal("0.20")
_GOOD_THRESHOLD = Decimal("0.40")
_GREAT_THRESHOLD = Decimal("0.60")


def classify_ndvi(mean_ndvi: Decimal) -> NDVIHealthStatus:
    """Classify a validated mean NDVI value using initial product heuristics."""
    if mean_ndvi < _BAD_THRESHOLD:
        return "Severe"
    if mean_ndvi < _GOOD_THRESHOLD:
        return "Bad"
    if mean_ndvi < _GREAT_THRESHOLD:
        return "Good"
    return "Great"
