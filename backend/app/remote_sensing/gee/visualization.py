from dataclasses import dataclass
from typing import Any, Mapping

from app.remote_sensing.exceptions import (
    RemoteSensingAuthenticationError,
    RemoteSensingProviderError,
)


NDVI_VISUALIZATION_MIN = -1.0
NDVI_VISUALIZATION_MAX = 1.0
NDVI_VISUALIZATION_PALETTE = (
    "#8B0000",
    "#F28E2B",
    "#F6D55C",
    "#8BC34A",
    "#1B7837",
)


@dataclass(frozen=True)
class GeeNdviVisualization:
    map_id: str
    tile_fetcher: Any
    minimum: float
    maximum: float
    palette: tuple[str, ...]


class GeeNdviVisualizationProcessor:
    """Create map tiles for an Earth Engine NDVI image."""

    def __init__(self, ee_module: Any | None = None) -> None:
        self._ee = ee_module

    def create(self, ndvi_image: Any) -> GeeNdviVisualization:
        try:
            result = ndvi_image.getMapId(self.visualization_parameters())
        except Exception as error:
            _raise_visualization_error(error)

        if not isinstance(result, Mapping):
            raise RemoteSensingProviderError(
                "Google Earth Engine returned invalid map metadata."
            )

        map_id = result.get("mapid")
        tile_fetcher = result.get("tile_fetcher")
        if not isinstance(map_id, str) or not map_id:
            raise RemoteSensingProviderError(
                "Google Earth Engine returned an invalid map ID."
            )
        if tile_fetcher is None or not callable(
            getattr(tile_fetcher, "fetch_tile", None)
        ):
            raise RemoteSensingProviderError(
                "Google Earth Engine returned no tile fetcher."
            )

        return GeeNdviVisualization(
            map_id=map_id,
            tile_fetcher=tile_fetcher,
            minimum=NDVI_VISUALIZATION_MIN,
            maximum=NDVI_VISUALIZATION_MAX,
            palette=NDVI_VISUALIZATION_PALETTE,
        )

    @staticmethod
    def visualization_parameters() -> dict[str, object]:
        return {
            "min": NDVI_VISUALIZATION_MIN,
            "max": NDVI_VISUALIZATION_MAX,
            "palette": list(NDVI_VISUALIZATION_PALETTE),
            "format": "png",
        }


def _raise_visualization_error(error: Exception) -> None:
    if _looks_like_authentication_error(error):
        raise RemoteSensingAuthenticationError(
            "Google Earth Engine authentication failed during visualization."
        ) from error
    raise RemoteSensingProviderError(
        "Google Earth Engine NDVI visualization failed."
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
