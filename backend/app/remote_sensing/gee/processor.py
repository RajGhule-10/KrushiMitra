from dataclasses import dataclass
from typing import Any, Mapping

from app.remote_sensing.exceptions import (
    RemoteSensingAuthenticationError,
    RemoteSensingProviderError,
)
from app.remote_sensing.models import SatelliteImage

from .provider import SENTINEL_2_SR_HARMONIZED_COLLECTION


@dataclass(frozen=True)
class GeeProcessedImage:
    """A clipped Earth Engine image and its farm AOI."""

    image_id: str
    image: Any
    aoi: Any


class GeeImageProcessor:
    """Prepare a selected Sentinel-2 image for downstream GEE analysis."""

    def __init__(self, ee_module: Any | None = None) -> None:
        self._ee = ee_module

    def process_image(
        self,
        image: SatelliteImage,
        geometry: Mapping[str, Any],
    ) -> GeeProcessedImage:
        self._validate_image(image)
        ee = self._earth_engine()

        try:
            aoi = _to_ee_geometry(ee, geometry)
            processed_image = ee.Image(
                f"{image.collection}/{image.image_id}"
            ).clip(aoi)
        except RemoteSensingProviderError:
            raise
        except Exception as error:
            _raise_processing_error(error)

        return GeeProcessedImage(
            image_id=image.image_id,
            image=processed_image,
            aoi=aoi,
        )

    @staticmethod
    def _validate_image(image: SatelliteImage) -> None:
        if image.provider != "google_earth_engine":
            raise RemoteSensingProviderError(
                "Only Google Earth Engine images are supported."
            )
        if image.collection != SENTINEL_2_SR_HARMONIZED_COLLECTION:
            raise RemoteSensingProviderError(
                "Only Sentinel-2 Surface Reflectance Harmonized images are supported."
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


def _to_ee_geometry(ee: Any, geometry: Mapping[str, Any]) -> Any:
    geometry_type = geometry.get("type")
    coordinates = geometry.get("coordinates")
    if geometry_type == "Polygon":
        return ee.Geometry.Polygon(coordinates)
    if geometry_type == "MultiPolygon":
        return ee.Geometry.MultiPolygon(coordinates)
    raise RemoteSensingProviderError(
        "Only Polygon and MultiPolygon geometries are supported."
    )


def _raise_processing_error(error: Exception) -> None:
    if _looks_like_authentication_error(error):
        raise RemoteSensingAuthenticationError(
            "Google Earth Engine authentication failed during image processing."
        ) from error
    raise RemoteSensingProviderError(
        "Google Earth Engine image processing failed."
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
