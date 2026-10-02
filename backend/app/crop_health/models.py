from dataclasses import dataclass
from decimal import Decimal
from typing import Literal


TrendDirection = Literal["Improving", "Stable", "Declining"]


@dataclass(frozen=True)
class CropHealthTrend:
    direction: TrendDirection
    first_ndvi: Decimal
    latest_ndvi: Decimal
    change: Decimal
    observation_count: int
