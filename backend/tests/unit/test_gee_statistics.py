import sys
from unittest.mock import Mock

import pytest

from app.remote_sensing.exceptions import (
    RemoteSensingAuthenticationError,
    RemoteSensingProviderError,
)
from app.remote_sensing.gee.ndvi import GeeNdviResult
from app.remote_sensing.gee.statistics import GeeNdviStatisticsProcessor


class FakeReduction:
    def __init__(self, result: object = None) -> None:
        self.getInfo = Mock(return_value={"nd": 0.42} if result is None else result)


class FakeNdviImage:
    def __init__(self, reduction: FakeReduction | None = None) -> None:
        self.reduction = reduction or FakeReduction()
        self.reduceRegion = Mock(return_value=self.reduction)
        self.getDownloadURL = Mock(
            side_effect=AssertionError("Downloads are not part of statistics extraction.")
        )


class FakeEarthEngine:
    def __init__(self) -> None:
        self.Initialize = Mock()
        self.Reducer = Mock()
        self.Reducer.mean = Mock(return_value="mean-reducer")


def _ndvi_result(image: FakeNdviImage | None = None) -> GeeNdviResult:
    return GeeNdviResult(
        image_id="S2A/test-image",
        ndvi_image=image or FakeNdviImage(),
        aoi={"type": "Polygon", "coordinates": []},
    )


def test_statistics_processor_can_be_instantiated():
    assert isinstance(GeeNdviStatisticsProcessor(FakeEarthEngine()), GeeNdviStatisticsProcessor)


def test_mean_uses_earth_engine_reducer_and_existing_ndvi_image():
    ee = FakeEarthEngine()
    image = FakeNdviImage()
    ndvi_result = _ndvi_result(image)

    result = GeeNdviStatisticsProcessor(ee).calculate_mean(ndvi_result)

    ee.Reducer.mean.assert_called_once_with()
    image.reduceRegion.assert_called_once_with(
        reducer="mean-reducer",
        geometry=ndvi_result.aoi,
        scale=10,
        maxPixels=10_000_000,
    )
    image.reduction.getInfo.assert_called_once_with()
    assert result == 0.42
    assert isinstance(result, float)


def test_numeric_ndvi_value_is_returned_as_float():
    ee = FakeEarthEngine()
    image = FakeNdviImage(FakeReduction({"nd": "0.75"}))

    result = GeeNdviStatisticsProcessor(ee).calculate_mean(_ndvi_result(image))

    assert result == 0.75
    assert isinstance(result, float)


def test_constructor_does_not_initialize_earth_engine():
    ee = FakeEarthEngine()

    GeeNdviStatisticsProcessor(ee)

    ee.Initialize.assert_not_called()


def test_lazy_import_path_does_not_initialize_earth_engine(monkeypatch):
    ee = FakeEarthEngine()
    monkeypatch.setitem(sys.modules, "ee", ee)

    result = GeeNdviStatisticsProcessor().calculate_mean(_ndvi_result())

    assert result == 0.42
    ee.Initialize.assert_not_called()


def test_authentication_errors_are_mapped():
    ee = FakeEarthEngine()
    image = FakeNdviImage()
    image.reduceRegion.side_effect = RuntimeError("permission denied")

    with pytest.raises(
        RemoteSensingAuthenticationError,
        match="authentication failed",
    ):
        GeeNdviStatisticsProcessor(ee).calculate_mean(_ndvi_result(image))


def test_provider_errors_are_mapped():
    ee = FakeEarthEngine()
    image = FakeNdviImage()
    image.reduceRegion.side_effect = RuntimeError("service unavailable")

    with pytest.raises(RemoteSensingProviderError, match="statistics extraction failed"):
        GeeNdviStatisticsProcessor(ee).calculate_mean(_ndvi_result(image))


def test_missing_nd_result_is_rejected():
    ee = FakeEarthEngine()
    image = FakeNdviImage(FakeReduction({}))

    with pytest.raises(RemoteSensingProviderError, match="Mean NDVI could not be obtained"):
        GeeNdviStatisticsProcessor(ee).calculate_mean(_ndvi_result(image))


def test_none_nd_result_is_rejected():
    ee = FakeEarthEngine()
    image = FakeNdviImage(FakeReduction({"nd": None}))

    with pytest.raises(RemoteSensingProviderError, match="Mean NDVI could not be obtained"):
        GeeNdviStatisticsProcessor(ee).calculate_mean(_ndvi_result(image))


def test_non_numeric_nd_result_is_rejected():
    ee = FakeEarthEngine()
    image = FakeNdviImage(FakeReduction({"nd": "not-a-number"}))

    with pytest.raises(RemoteSensingProviderError, match="Mean NDVI could not be obtained"):
        GeeNdviStatisticsProcessor(ee).calculate_mean(_ndvi_result(image))


def test_nan_nd_result_is_rejected():
    ee = FakeEarthEngine()
    image = FakeNdviImage(FakeReduction({"nd": float("nan")}))

    with pytest.raises(RemoteSensingProviderError, match="Mean NDVI could not be obtained"):
        GeeNdviStatisticsProcessor(ee).calculate_mean(_ndvi_result(image))


def test_positive_infinity_nd_result_is_rejected():
    ee = FakeEarthEngine()
    image = FakeNdviImage(FakeReduction({"nd": float("inf")}))

    with pytest.raises(RemoteSensingProviderError, match="Mean NDVI could not be obtained"):
        GeeNdviStatisticsProcessor(ee).calculate_mean(_ndvi_result(image))


def test_statistics_extraction_does_not_download_raster_data():
    ee = FakeEarthEngine()
    image = FakeNdviImage()

    GeeNdviStatisticsProcessor(ee).calculate_mean(_ndvi_result(image))

    image.getDownloadURL.assert_not_called()
