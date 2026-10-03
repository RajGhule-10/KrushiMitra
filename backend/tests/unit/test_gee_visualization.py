from types import SimpleNamespace

import pytest

from app.remote_sensing.exceptions import (
    RemoteSensingAuthenticationError,
    RemoteSensingProviderError,
)
from app.remote_sensing.gee.visualization import (
    NDVI_VISUALIZATION_PALETTE,
    GeeNdviVisualizationProcessor,
)


class FakeNdviImage:
    def __init__(self, result=None, error=None):
        self.result = result
        self.error = error
        self.calls = []

    def getMapId(self, parameters):
        self.calls.append(parameters)
        if self.error is not None:
            raise self.error
        return self.result


class FakeTileFetcher:
    def fetch_tile(self, x, y, z):
        return b"png"


def test_creates_deterministic_ndvi_visualization():
    image = FakeNdviImage(
        {
            "mapid": "projects/demo/maps/123",
            "token": "",
            "tile_fetcher": FakeTileFetcher(),
        }
    )

    result = GeeNdviVisualizationProcessor().create(image)

    assert image.calls == [
        {
            "min": -1.0,
            "max": 1.0,
            "palette": list(NDVI_VISUALIZATION_PALETTE),
            "format": "png",
        }
    ]
    assert result.map_id == "projects/demo/maps/123"
    assert result.tile_fetcher.fetch_tile(1, 2, 3) == b"png"


@pytest.mark.parametrize(
    "result, message",
    [
        ({"mapid": "map"}, "no tile fetcher"),
        ({"tile_fetcher": FakeTileFetcher()}, "invalid map ID"),
        (SimpleNamespace(), "invalid map metadata"),
    ],
)
def test_rejects_invalid_map_metadata(result, message):
    with pytest.raises(RemoteSensingProviderError, match=message):
        GeeNdviVisualizationProcessor().create(FakeNdviImage(result))


def test_maps_authentication_failure():
    with pytest.raises(RemoteSensingAuthenticationError):
        GeeNdviVisualizationProcessor().create(
            FakeNdviImage(error=PermissionError("permission denied"))
        )


def test_maps_generic_failure():
    with pytest.raises(RemoteSensingProviderError, match="visualization failed"):
        GeeNdviVisualizationProcessor().create(
            FakeNdviImage(error=RuntimeError("upstream failed"))
        )
