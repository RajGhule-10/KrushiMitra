"""Google Earth Engine configuration and initialization helpers."""

from .client import initialize_earth_engine
from .provider import (
    GEE_PROVIDER_NAME,
    SENTINEL_2_SR_HARMONIZED_COLLECTION,
    GeeRemoteSensingProvider,
)

__all__ = [
    "GEE_PROVIDER_NAME",
    "SENTINEL_2_SR_HARMONIZED_COLLECTION",
    "GeeRemoteSensingProvider",
    "initialize_earth_engine",
]
