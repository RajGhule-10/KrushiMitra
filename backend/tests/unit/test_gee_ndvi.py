import sys
from unittest.mock import Mock

import pytest

from app.remote_sensing.exceptions import (
    RemoteSensingAuthenticationError,
    RemoteSensingProviderError,
)
from app.remote_sensing.gee.ndvi import GeeNdviProcessor, GeeNdviResult
from app.remote_sensing.gee.processor import GeeProcessedImage


class FakeImage:
    def __init__(self) -> None:
        self.normalizedDifference = Mock(return_value="ndvi-image")
        self.getDownloadURL = Mock(
            side_effect=AssertionError("Downloads are not part of NDVI computation.")
        )


class FakeEarthEngine:
    def __init__(self) -> None:
        self.Initialize = Mock()


def _processed_image(image: FakeImage | None = None) -> GeeProcessedImage:
    return GeeProcessedImage(
        image_id="S2A/test-image",
        image=image or FakeImage(),
        aoi={"type": "Polygon", "coordinates": []},
    )


def test_ndvi_uses_sentinel_2_nir_and_red_bands():
    ee = FakeEarthEngine()
    image = FakeImage()

    result = GeeNdviProcessor(ee).calculate_ndvi(_processed_image(image))

    image.normalizedDifference.assert_called_once_with(["B8", "B4"])
    assert isinstance(result, GeeNdviResult)
    assert result.ndvi_image == "ndvi-image"


def test_ndvi_result_preserves_image_id_and_aoi():
    ee = FakeEarthEngine()
    processed_image = _processed_image()

    result = GeeNdviProcessor(ee).calculate_ndvi(processed_image)

    assert result.image_id == processed_image.image_id
    assert result.aoi is processed_image.aoi


def test_constructor_does_not_initialize_earth_engine():
    ee = FakeEarthEngine()

    GeeNdviProcessor(ee)

    ee.Initialize.assert_not_called()


def test_lazy_import_path_does_not_initialize_earth_engine(monkeypatch):
    ee = FakeEarthEngine()
    monkeypatch.setitem(sys.modules, "ee", ee)

    result = GeeNdviProcessor().calculate_ndvi(_processed_image())

    assert result.ndvi_image == "ndvi-image"
    ee.Initialize.assert_not_called()


def test_authentication_errors_are_mapped():
    ee = FakeEarthEngine()
    image = FakeImage()
    image.normalizedDifference.side_effect = RuntimeError("permission denied")

    with pytest.raises(
        RemoteSensingAuthenticationError,
        match="authentication failed",
    ):
        GeeNdviProcessor(ee).calculate_ndvi(_processed_image(image))


def test_provider_errors_are_mapped():
    ee = FakeEarthEngine()
    image = FakeImage()
    image.normalizedDifference.side_effect = RuntimeError("service unavailable")

    with pytest.raises(RemoteSensingProviderError, match="NDVI computation failed"):
        GeeNdviProcessor(ee).calculate_ndvi(_processed_image(image))


def test_ndvi_does_not_download_image_data():
    ee = FakeEarthEngine()
    image = FakeImage()

    GeeNdviProcessor(ee).calculate_ndvi(_processed_image(image))

    image.getDownloadURL.assert_not_called()
