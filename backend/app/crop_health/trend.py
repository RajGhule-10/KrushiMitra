from decimal import Decimal
from typing import Sequence

from .models import CropHealthTrend


TREND_CHANGE_THRESHOLD = Decimal("0.05")


def calculate_ndvi_trend(ndvi_values: Sequence[Decimal]) -> CropHealthTrend:
    if len(ndvi_values) < 2:
        raise ValueError("At least two NDVI observations are required.")

    first_ndvi = ndvi_values[0]
    latest_ndvi = ndvi_values[-1]
    change = latest_ndvi - first_ndvi

    if change > TREND_CHANGE_THRESHOLD:
        direction = "Improving"
    elif change < -TREND_CHANGE_THRESHOLD:
        direction = "Declining"
    else:
        direction = "Stable"

    return CropHealthTrend(
        direction=direction,
        first_ndvi=first_ndvi,
        latest_ndvi=latest_ndvi,
        change=change,
        observation_count=len(ndvi_values),
    )
