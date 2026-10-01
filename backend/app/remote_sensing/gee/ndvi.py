from dataclasses import dataclass
from typing import Any

from app.remote_sensing.exceptions import (
    RemoteSensingAuthenticationError,
    RemoteSensingProviderError,
)

from .processor import GeeProcessedImage


@dataclass(frozen=True)
class GeeNdviResult:
    """An NDVI image derived from a processed Sentinel-2 image."""

    image_id: str
    ndvi_image: Any
    aoi: Any


class GeeNdviProcessor:
    """Calculate NDVI for a clipped Sentinel-2 Earth Engine image."""

    def __init__(self, ee_module: Any | None = None) -> None:
        self._ee = ee_module

    def calculate_ndvi(self, processed_image: GeeProcessedImage) -> GeeNdviResult:
        self._earth_engine()

        try:
            ndvi_image = processed_image.image.normalizedDifference(["B8", "B4"])
        except Exception as error:
            _raise_ndvi_error(error)

        return GeeNdviResult(
            image_id=processed_image.image_id,
            ndvi_image=ndvi_image,
            aoi=processed_image.aoi,
        )

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


def _raise_ndvi_error(error: Exception) -> None:
    if _looks_like_authentication_error(error):
        raise RemoteSensingAuthenticationError(
            "Google Earth Engine authentication failed during NDVI computation."
        ) from error
    raise RemoteSensingProviderError(
        "Google Earth Engine NDVI computation failed."
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
