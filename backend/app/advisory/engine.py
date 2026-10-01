from .models import Advisory
from .rules import ADVISORY_RULES


def generate_advisory(health_status: str) -> Advisory:
    """Generate a deterministic advisory for a supported health status."""
    try:
        return ADVISORY_RULES[health_status]
    except KeyError as error:
        raise ValueError(
            f"Unsupported crop health status: {health_status!r}"
        ) from error
