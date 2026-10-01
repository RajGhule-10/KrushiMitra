from datetime import date, datetime, timedelta, timezone
from typing import Any, Mapping

from app.remote_sensing.base import RemoteSensingProvider
from app.remote_sensing.exceptions import (
    RemoteSensingAuthenticationError,
    RemoteSensingProviderError,
)
from app.remote_sensing.models import SatelliteImage

SENTINEL_2_SR_HARMONIZED_COLLECTION = "COPERNICUS/S2_SR_HARMONIZED"
GEE_PROVIDER_NAME = "google_earth_engine"


class GeeRemoteSensingProvider(RemoteSensingProvider):
    """Google Earth Engine provider for Sentinel-2 image discovery."""

    def __init__(self, ee_module: Any | None = None) -> None:
        self._ee = ee_module

    def _search_images(
        self,
        geometry: Mapping[str, Any],
        start_date: date,
        end_date: date,
        max_cloud_percentage: float | None = None,
    ) -> list[SatelliteImage]:
        ee = self._earth_engine()

        try:
            aoi = _to_ee_geometry(ee, geometry)
            collection = ee.ImageCollection(
                SENTINEL_2_SR_HARMONIZED_COLLECTION
            ).filterBounds(aoi)
            collection = collection.filterDate(
                start_date.isoformat(),
                (end_date + timedelta(days=1)).isoformat(),
            )
            if max_cloud_percentage is not None:
                collection = collection.filter(
                    ee.Filter.lte(
                        "CLOUDY_PIXEL_PERCENTAGE",
                        max_cloud_percentage,
                    )
                )

            image_ids = _get_info(
                collection.aggregate_array("system:index")
            )
            timestamps = _get_info(
                collection.aggregate_array("system:time_start")
            )
            cloud_percentages = _get_info(
                collection.aggregate_array("CLOUDY_PIXEL_PERCENTAGE")
            )
        except RemoteSensingProviderError:
            raise
        except Exception as error:
            _raise_provider_error(error)

        if not (
            isinstance(image_ids, list)
            and isinstance(timestamps, list)
            and isinstance(cloud_percentages, list)
        ):
            raise RemoteSensingProviderError(
                "Google Earth Engine returned invalid image metadata."
            )
        if not (
            len(image_ids) == len(timestamps) == len(cloud_percentages)
        ):
            raise RemoteSensingProviderError(
                "Google Earth Engine returned incomplete image metadata."
            )

        images = [
            SatelliteImage(
                image_id=_image_id(image_id),
                acquisition_date=_acquisition_date(timestamp),
                cloud_percentage=_cloud_percentage(cloud_percentage),
                provider=GEE_PROVIDER_NAME,
                collection=SENTINEL_2_SR_HARMONIZED_COLLECTION,
            )
            for image_id, timestamp, cloud_percentage in zip(
                image_ids,
                timestamps,
                cloud_percentages,
                strict=True,
            )
        ]
        return sorted(
            images,
            key=lambda image: (image.acquisition_date, image.image_id),
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


def _get_info(computed_object: Any) -> Any:
    return computed_object.getInfo()


def _image_id(value: Any) -> str:
    if not isinstance(value, str) or not value:
        raise RemoteSensingProviderError(
            "Google Earth Engine returned an image without an ID."
        )
    return value


def _acquisition_date(value: Any) -> date:
    if not isinstance(value, (int, float)):
        raise RemoteSensingProviderError(
            "Google Earth Engine returned an image without an acquisition date."
        )
    return datetime.fromtimestamp(value / 1000, tz=timezone.utc).date()


def _cloud_percentage(value: Any) -> float | None:
    if value is None:
        return None
    if not isinstance(value, (int, float)):
        raise RemoteSensingProviderError(
            "Google Earth Engine returned invalid cloud metadata."
        )
    return float(value)


def _raise_provider_error(error: Exception) -> None:
    if _looks_like_authentication_error(error):
        raise RemoteSensingAuthenticationError(
            "Google Earth Engine authentication failed."
        ) from error
    raise RemoteSensingProviderError(
        "Google Earth Engine image search failed."
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
