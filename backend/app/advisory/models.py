from dataclasses import dataclass
from typing import Literal

AdvisoryPriority = Literal["low", "medium", "high"]
HealthStatus = Literal["Severe", "Bad", "Good", "Great"]


@dataclass(frozen=True)
class Advisory:
    status: HealthStatus
    priority: AdvisoryPriority
    title: str
    message: str
