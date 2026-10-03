from datetime import date
from types import SimpleNamespace
from uuid import UUID

import pytest

from app.core.errors import NotFoundException
from app.remote_sensing.exceptions import RemoteSensingProviderError
from app.remote_sensing.models import SatelliteImage
from app.remote_sensing.gee.visualization import GeeNdviVisualization
from app.services.crop_health_map import CropHealthMapService


USER_ID = UUID("00000000-0000-0000-0000-000000000001")
PROFILE_ID = UUID("00000000-0000-0000-0000-000000000002")
CROP_ID = UUID("00000000-0000-0000-0000-000000000003")
FARM_ID = UUID("00000000-0000-0000-0000-000000000004")


class FakeProfileRepository:
    def __init__(self, profile):
        self.profile = profile
        self.calls = []

    def get_by_user_id(self, user_id):
        self.calls.append(user_id)
        return self.profile


class FakeCropRepository:
    def __init__(self, crop):
        self.crop = crop
        self.calls = []

    def get_crop_by_id_for_farmer(self, crop_id, profile_id):
        self.calls.append((crop_id, profile_id))
        return self.crop


class FakeBoundaryRepository:
    def __init__(self, boundary, geometry):
        self.boundary = boundary
        self.geometry = geometry
        self.calls = []

    def get_by_farm_id(self, farm_id):
        self.calls.append(("boundary", farm_id))
        return self.boundary

    def get_geometry_as_geojson(self, boundary):
        self.calls.append(("geometry", boundary))
        return self.geometry


class FakeProvider:
    def __init__(self, images, error=None):
        self.images = images
        self.error = error
        self.calls = []

    def search_images(self, geometry, start_date, end_date, max_cloud_percentage):
        self.calls.append((geometry, start_date, end_date, max_cloud_percentage))
        if self.error is not None:
            raise self.error
        return self.images


class FakeImageProcessor:
    def __init__(self):
        self.calls = []

    def process_image(self, image, geometry):
        self.calls.append((image, geometry))
        return SimpleNamespace(image_id=image.image_id)


class FakeNdviProcessor:
    def __init__(self):
        self.calls = []

    def calculate_ndvi(self, processed):
        self.calls.append(processed)
        return SimpleNamespace(ndvi_image=SimpleNamespace())


class FakeVisualizationProcessor:
    def __init__(self):
        self.calls = []

    def create(self, ndvi_image):
        self.calls.append(ndvi_image)
        return GeeNdviVisualization(
            map_id="map",
            tile_fetcher=SimpleNamespace(fetch_tile=lambda x, y, z: b"png"),
            minimum=-1.0,
            maximum=1.0,
            palette=("#000000", "#FFFFFF"),
        )


def build_service(
    *,
    profile=SimpleNamespace(id=PROFILE_ID),
    crop=SimpleNamespace(id=CROP_ID, farm_id=FARM_ID),
    boundary=object(),
    images=None,
    provider_error=None,
):
    provider = FakeProvider(images or [], provider_error)
    image_processor = FakeImageProcessor()
    ndvi_processor = FakeNdviProcessor()
    visualization_processor = FakeVisualizationProcessor()
    service = CropHealthMapService.__new__(CropHealthMapService)
    service.farmer_profile_repository = FakeProfileRepository(profile)
    service.crop_health_repository = FakeCropRepository(crop)
    service.farm_boundary_repository = FakeBoundaryRepository(
        boundary,
        {"type": "MultiPolygon", "coordinates": []},
    )
    service.provider = provider
    service.image_processor = image_processor
    service.ndvi_processor = ndvi_processor
    service.visualization_processor = visualization_processor
    return service, provider, image_processor, ndvi_processor


def image(image_id, acquisition_date):
    return SatelliteImage(
        image_id=image_id,
        acquisition_date=acquisition_date,
        cloud_percentage=8.0,
        provider="google_earth_engine",
        collection="COPERNICUS/S2_SR_HARMONIZED",
    )


def test_owned_crop_returns_latest_visualization_without_persistence():
    service, provider, image_processor, ndvi_processor = build_service(
        images=[
            image("older", date(2026, 9, 20)),
            image("latest", date(2026, 10, 1)),
        ],
    )

    result = service.get_crop_health_map(
        SimpleNamespace(id=USER_ID),
        CROP_ID,
        date(2026, 10, 2),
    )

    assert result.crop_id == CROP_ID
    assert result.observation_date == date(2026, 10, 1)
    assert result.data_source == "sentinel-2"
    assert provider.calls[0][1:] == (
        date(2026, 9, 2),
        date(2026, 10, 2),
        20.0,
    )
    assert image_processor.calls[0][0].image_id == "latest"
    assert len(ndvi_processor.calls) == 1


def test_missing_or_inaccessible_crop_returns_not_found():
    service, *_ = build_service(crop=None)

    with pytest.raises(NotFoundException, match="Crop not found"):
        service.get_crop_health_map(SimpleNamespace(id=USER_ID), CROP_ID)


def test_missing_boundary_returns_not_found():
    service, *_ = build_service(boundary=None)

    with pytest.raises(NotFoundException, match="Farm boundary not found"):
        service.get_crop_health_map(SimpleNamespace(id=USER_ID), CROP_ID)


def test_provider_failure_propagates():
    service, *_ = build_service(
        provider_error=RemoteSensingProviderError("provider failed"),
    )

    with pytest.raises(RemoteSensingProviderError, match="provider failed"):
        service.get_crop_health_map(SimpleNamespace(id=USER_ID), CROP_ID)


def test_tile_coordinates_are_validated():
    service, *_ = build_service(images=[image("image", date(2026, 10, 1))])

    with pytest.raises(ValueError, match="Invalid map tile coordinates"):
        service.get_tile(SimpleNamespace(id=USER_ID), CROP_ID, 2, 4, 0)
