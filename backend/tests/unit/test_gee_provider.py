from datetime import date
import sys
from types import SimpleNamespace
from unittest.mock import Mock

import pytest

from app.remote_sensing.base import RemoteSensingProvider
from app.remote_sensing.exceptions import (
    RemoteSensingAuthenticationError,
    RemoteSensingProviderError,
)
from app.remote_sensing.gee.provider import (
    SENTINEL_2_SR_HARMONIZED_COLLECTION,
    GeeRemoteSensingProvider,
)


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


class FakeComputed:
    def __init__(self, value):
        self.value = value

    def getInfo(self):
        return self.value


class FakeCollection:
    def __init__(self, metadata):
        self.metadata = metadata
        self.filter_bounds_argument = None
        self.date_arguments = None
        self.filter_argument = None
        self.download_methods_called = False

    def filterBounds(self, geometry):
        self.filter_bounds_argument = geometry
        return self

    def filterDate(self, start, end):
        self.date_arguments = (start, end)
        return self

    def filter(self, expression):
        self.filter_argument = expression
        return self

    def aggregate_array(self, property_name):
        return FakeComputed(self.metadata[property_name])

    def getDownloadURL(self, *args, **kwargs):
        self.download_methods_called = True
        raise AssertionError("Image downloads are not part of image discovery.")


class FakeGeometry:
    def __init__(self):
        self.Polygon = Mock(side_effect=lambda coordinates: ("Polygon", coordinates))
        self.MultiPolygon = Mock(
            side_effect=lambda coordinates: ("MultiPolygon", coordinates)
        )


class FakeFilter:
    def __init__(self):
        self.lte = Mock(return_value=("lte",))


class FakeEarthEngine:
    def __init__(self, metadata):
        self.Initialize = Mock()
        self.Geometry = FakeGeometry()
        self.Filter = FakeFilter()
        self.collection = FakeCollection(metadata)
        self.ImageCollection = Mock(
            return_value=self.collection,
        )


def _provider(metadata=None):
    metadata = metadata or {
        "system:index": ["image-b", "image-a"],
        "system:time_start": [1727740800000, 1727654400000],
        "CLOUDY_PIXEL_PERCENTAGE": [20.0, None],
    }
    ee = FakeEarthEngine(metadata)
    return GeeRemoteSensingProvider(ee), ee


def test_provider_implements_remote_sensing_provider():
    provider, _ = _provider()

    assert isinstance(provider, RemoteSensingProvider)


def test_polygon_geometry_collection_and_inclusive_dates():
    provider, ee = _provider()

    provider.search_images(
        POLYGON,
        date(2024, 10, 1),
        date(2024, 10, 3),
    )

    ee.ImageCollection.assert_called_once_with(
        SENTINEL_2_SR_HARMONIZED_COLLECTION
    )
    ee.Geometry.Polygon.assert_called_once_with(POLYGON["coordinates"])
    assert ee.collection.filter_bounds_argument == (
        "Polygon",
        POLYGON["coordinates"],
    )
    assert ee.collection.date_arguments == ("2024-10-01", "2024-10-04")


def test_multipolygon_geometry_is_translated():
    provider, ee = _provider()

    provider.search_images(
        MULTIPOLYGON,
        date(2024, 10, 1),
        date(2024, 10, 1),
    )

    ee.Geometry.MultiPolygon.assert_called_once_with(MULTIPOLYGON["coordinates"])


def test_cloud_filter_is_applied_when_supplied():
    provider, ee = _provider()

    provider.search_images(
        POLYGON,
        date(2024, 10, 1),
        date(2024, 10, 1),
        max_cloud_percentage=15,
    )

    ee.Filter.lte.assert_called_once_with("CLOUDY_PIXEL_PERCENTAGE", 15)
    assert ee.collection.filter_argument == ("lte",)


def test_cloud_filter_is_omitted_when_not_supplied():
    provider, ee = _provider()

    provider.search_images(POLYGON, date(2024, 10, 1), date(2024, 10, 1))

    ee.Filter.lte.assert_not_called()
    assert ee.collection.filter_argument is None


def test_metadata_is_normalized_and_sorted():
    provider, _ = _provider()

    images = provider.search_images(
        POLYGON,
        date(2024, 10, 1),
        date(2024, 10, 3),
    )

    assert [image.image_id for image in images] == ["image-a", "image-b"]
    assert [image.acquisition_date for image in images] == [
        date(2024, 9, 30),
        date(2024, 10, 1),
    ]
    assert images[0].cloud_percentage is None
    assert images[1].cloud_percentage == 20
    assert images[0].provider == "google_earth_engine"
    assert images[0].collection == SENTINEL_2_SR_HARMONIZED_COLLECTION


def test_same_date_results_are_sorted_by_image_id():
    provider, _ = _provider(
        {
            "system:index": ["z-image", "a-image"],
            "system:time_start": [1727654400000, 1727654400000],
            "CLOUDY_PIXEL_PERCENTAGE": [5, 5],
        }
    )

    images = provider.search_images(
        POLYGON,
        date(2024, 10, 1),
        date(2024, 10, 1),
    )

    assert [image.image_id for image in images] == ["a-image", "z-image"]


def test_provider_errors_are_mapped():
    provider, ee = _provider()
    ee.collection.aggregate_array = Mock(side_effect=RuntimeError("service failed"))

    with pytest.raises(RemoteSensingProviderError, match="image search failed"):
        provider.search_images(POLYGON, date(2024, 10, 1), date(2024, 10, 1))


def test_authentication_errors_are_mapped():
    provider, ee = _provider()
    ee.collection.aggregate_array = Mock(
        side_effect=RuntimeError("permission denied")
    )

    with pytest.raises(
        RemoteSensingAuthenticationError,
        match="authentication failed",
    ):
        provider.search_images(POLYGON, date(2024, 10, 1), date(2024, 10, 1))


def test_unsupported_geometry_is_rejected():
    provider, _ = _provider()

    with pytest.raises(RemoteSensingProviderError, match="Polygon"):
        provider.search_images(
            {"type": "Point", "coordinates": [73.8, 18.5]},
            date(2024, 10, 1),
            date(2024, 10, 1),
        )


def test_no_download_api_is_called():
    provider, ee = _provider()

    provider.search_images(POLYGON, date(2024, 10, 1), date(2024, 10, 1))

    assert ee.collection.download_methods_called is False


def test_constructor_does_not_initialize_earth_engine():
    provider, ee = _provider()

    assert provider is not None
    ee.Initialize.assert_not_called()


def test_constructor_without_injected_module_does_not_initialize_earth_engine(
    monkeypatch,
):
    fake_ee = SimpleNamespace(Initialize=Mock())
    monkeypatch.setitem(sys.modules, "ee", fake_ee)

    provider = GeeRemoteSensingProvider()

    assert provider is not None
    fake_ee.Initialize.assert_not_called()
