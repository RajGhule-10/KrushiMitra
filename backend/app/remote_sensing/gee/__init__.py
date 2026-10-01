"""Google Earth Engine configuration and initialization helpers."""

from .client import initialize_earth_engine
from .ndvi import GeeNdviProcessor, GeeNdviResult
from .statistics import GeeNdviStatisticsProcessor
from .provider import (
    GEE_PROVIDER_NAME,
    SENTINEL_2_SR_HARMONIZED_COLLECTION,
    GeeRemoteSensingProvider,
)
from .processor import GeeImageProcessor, GeeProcessedImage

__all__ = [
    "GEE_PROVIDER_NAME",
    "SENTINEL_2_SR_HARMONIZED_COLLECTION",
    "GeeRemoteSensingProvider",
    "GeeImageProcessor",
    "GeeProcessedImage",
    "GeeNdviProcessor",
    "GeeNdviResult",
    "GeeNdviStatisticsProcessor",
    "initialize_earth_engine",
]
