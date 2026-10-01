import math
from typing import Any, Mapping

from app.remote_sensing.exceptions import (
    RemoteSensingAuthenticationError,
    RemoteSensingProviderError,
)

from .ndvi import GeeNdviResult


class GeeNdviStatisticsProcessor:
    """Extract aggregate NDVI statistics from Earth Engine."""

    _SCALE_METERS = 10
    _MAX_PIXELS = 10_000_000

    def __init__(self, ee_module: Any | None = None) -> None:
        self._ee = ee_module

    def calculate_mean(self, ndvi_result: GeeNdviResult) -> float:
        ee = self._earth_engine()

        try:
            reduction = ndvi_result.ndvi_image.reduceRegion(
                reducer=ee.Reducer.mean(),
                geometry=ndvi_result.aoi,
                scale=self._SCALE_METERS,
                maxPixels=self._MAX_PIXELS,
            )
            statistics = reduction.getInfo()
        except Exception as error:
            _raise_statistics_error(error)

        return _extract_mean_ndvi(statistics)

    def _earth_engine(self) -> Any:
        if self._ee is not None:
            return self._ee

        try:
            import ee
        except ImportError as error:
            raise RemoteSensingProviderError(
                "The Google Earth Engine SDK is not installed."
            ) from error
        self._ee = ee
        return ee


def _extract_mean_ndvi(statistics: Any) -> float:
    if not isinstance(statistics, Mapping):
        raise RemoteSensingProviderError("Mean NDVI could not be obtained.")

    value = statistics.get("nd")
    if value is None or isinstance(value, bool):
        raise RemoteSensingProviderError("Mean NDVI could not be obtained.")

    try:
        mean_ndvi = float(value)
    except (TypeError, ValueError) as error:
        raise RemoteSensingProviderError("Mean NDVI could not be obtained.") from error

    if not math.isfinite(mean_ndvi):
        raise RemoteSensingProviderError("Mean NDVI could not be obtained.")

    return mean_ndvi


def _raise_statistics_error(error: Exception) -> None:
    if _looks_like_authentication_error(error):
        raise RemoteSensingAuthenticationError(
            "Google Earth Engine authentication failed during NDVI statistics extraction."
        ) from error
    raise RemoteSensingProviderError(
        "Google Earth Engine NDVI statistics extraction failed."
    ) from error


def _looks_like_authentication_error(error: Exception) -> bool:
    error_name = type(error).__name__.lower()
    error_message = str(error).lower()
    authentication_terms = (
        "auth",
        "credential",
        "permission",
        "unauthorized",
        "forbidden",
    )
    return any(
        term in error_name or term in error_message
        for term in authentication_terms
    )
