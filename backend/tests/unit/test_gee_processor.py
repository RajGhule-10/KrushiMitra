import sys
from datetime import date
from types import SimpleNamespace
from unittest.mock import Mock

import pytest

from app.remote_sensing.exceptions import (
    RemoteSensingAuthenticationError,
    RemoteSensingProviderError,
)
from app.remote_sensing.gee.processor import (
    GeeImageProcessor,
    GeeProcessedImage,
)
from app.remote_sensing.gee.provider import SENTINEL_2_SR_HARMONIZED_COLLECTION
from app.remote_sensing.models import SatelliteImage


POLYGON = {
    "type": "Polygon",
    "coordinates": [
        [
            [73.8, 18.5],
            [73.81, 18.5],
            [73.8, 18.51],
            [73.8, 18.5],
        ]
    ],
}
MULTIPOLYGON = {
    "type": "MultiPolygon",
    "coordinates": [
        POLYGON["coordinates"],
        [
            [
                [73.82, 18.5],
                [73.83, 18.5],
                [73.82, 18.51],
                [73.82, 18.5],
            ]
        ],
    ],
}


def _satellite_image(
    provider="google_earth_engine",
    collection=SENTINEL_2_SR_HARMONIZED_COLLECTION,
):
    return SatelliteImage(
        image_id="S2A/test-image",
        acquisition_date=date(2026, 9, 30),
        cloud_percentage=10,
        provider=provider,
        collection=collection,
    )


class FakeGeometry:
    def __init__(self):
        self.Polygon = Mock(side_effect=lambda coordinates: ("Polygon", coordinates))
        self.MultiPolygon = Mock(
            side_effect=lambda coordinates: ("MultiPolygon", coordinates)
        )


class FakeImage:
    def __init__(self):
        self.clip = Mock(return_value="clipped-image")
        self.getDownloadURL = Mock(
            side_effect=AssertionError("Downloads are not part of processing.")
        )


class FakeEarthEngine:
    def __init__(self):
        self.Initialize = Mock()
        self.Geometry = FakeGeometry()
        self.image = FakeImage()
        self.Image = Mock(return_value=self.image)


def test_processor_can_be_instantiated():
    assert isinstance(GeeImageProcessor(FakeEarthEngine()), GeeImageProcessor)


def test_polygon_is_converted_and_image_is_clipped():
    ee = FakeEarthEngine()
    result = GeeImageProcessor(ee).process_image(_satellite_image(), POLYGON)

    ee.Geometry.Polygon.assert_called_once_with(POLYGON["coordinates"])
    ee.Image.assert_called_once_with("S2A/test-image")
    ee.image.clip.assert_called_once_with(("Polygon", POLYGON["coordinates"]))
    assert isinstance(result, GeeProcessedImage)
    assert result.image_id == "S2A/test-image"
    assert result.image == "clipped-image"
    assert result.aoi == ("Polygon", POLYGON["coordinates"])


def test_multipolygon_is_converted():
    ee = FakeEarthEngine()

    result = GeeImageProcessor(ee).process_image(_satellite_image(), MULTIPOLYGON)

    ee.Geometry.MultiPolygon.assert_called_once_with(MULTIPOLYGON["coordinates"])
    assert result.aoi == ("MultiPolygon", MULTIPOLYGON["coordinates"])


def test_provider_and_collection_are_validated():
    ee = FakeEarthEngine()

    with pytest.raises(RemoteSensingProviderError, match="Google Earth Engine"):
        GeeImageProcessor(ee).process_image(
            _satellite_image(provider="other"),
            POLYGON,
        )
    with pytest.raises(RemoteSensingProviderError, match="Sentinel-2"):
        GeeImageProcessor(ee).process_image(
            _satellite_image(collection="other/collection"),
            POLYGON,
        )
    ee.Image.assert_not_called()


def test_unsupported_geometry_is_rejected():
    ee = FakeEarthEngine()

    with pytest.raises(RemoteSensingProviderError, match="Polygon"):
        GeeImageProcessor(ee).process_image(
            _satellite_image(),
            {"type": "Point", "coordinates": [73.8, 18.5]},
        )


def test_processing_errors_are_mapped():
    ee = FakeEarthEngine()
    ee.Image.side_effect = RuntimeError("service failed")

    with pytest.raises(
        RemoteSensingProviderError,
        match="image processing failed",
    ):
        GeeImageProcessor(ee).process_image(_satellite_image(), POLYGON)


def test_authentication_errors_are_mapped():
    ee = FakeEarthEngine()
    ee.Image.side_effect = RuntimeError("permission denied")

    with pytest.raises(
        RemoteSensingAuthenticationError,
        match="authentication failed",
    ):
        GeeImageProcessor(ee).process_image(_satellite_image(), POLYGON)


def test_no_download_api_is_called():
    ee = FakeEarthEngine()

    GeeImageProcessor(ee).process_image(_satellite_image(), POLYGON)

    ee.image.getDownloadURL.assert_not_called()


def test_constructor_does_not_initialize_earth_engine():
    ee = FakeEarthEngine()

    GeeImageProcessor(ee)

    ee.Initialize.assert_not_called()


def test_no_injected_module_does_not_initialize_earth_engine(monkeypatch):
    fake_ee = FakeEarthEngine()
    monkeypatch.setitem(sys.modules, "ee", fake_ee)

    processor = GeeImageProcessor()
    result = processor.process_image(_satellite_image(), POLYGON)

    assert result.image_id == "S2A/test-image"
    fake_ee.Initialize.assert_not_called()
