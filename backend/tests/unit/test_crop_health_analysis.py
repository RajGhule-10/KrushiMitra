from dataclasses import FrozenInstanceError
from datetime import date, timedelta
from decimal import Decimal
from types import SimpleNamespace
from uuid import UUID

import pytest

from app.core.errors import NotFoundException
from app.models.advisory import Advisory
from app.models.observation import CropObservation, HealthMetric
from app.remote_sensing.exceptions import RemoteSensingProviderError
from app.remote_sensing.models import SatelliteImage
from app.services.crop_health_analysis import (
    DEFAULT_LOOKBACK_DAYS,
    DEFAULT_MAX_CLOUD_PERCENTAGE,
    CropHealthAnalysisResult,
    CropHealthAnalysisService,
)


USER_ID = UUID("00000000-0000-0000-0000-000000000001")
PROFILE_ID = UUID("00000000-0000-0000-0000-000000000002")
CROP_ID = UUID("00000000-0000-0000-0000-000000000003")
FARM_ID = UUID("00000000-0000-0000-0000-000000000004")
BOUNDARY_ID = UUID("00000000-0000-0000-0000-000000000005")
OBSERVATION_ID = UUID("00000000-0000-0000-0000-000000000006")
METRIC_ID = UUID("00000000-0000-0000-0000-000000000007")
ADVISORY_ID = UUID("00000000-0000-0000-0000-000000000008")
GEOMETRY = {"type": "Polygon", "coordinates": [[[18.5, 73.8]]]}


class FakeFarmerProfileRepository:
    def __init__(self, profile):
        self.profile = profile
        self.calls = []

    def get_by_user_id(self, user_id):
        self.calls.append(user_id)
        return self.profile


class FakeCropHealthRepository:
    def __init__(self, crop):
        self.crop = crop
        self.calls = []

    def get_crop_by_id_for_farmer(self, crop_id, farmer_profile_id):
        self.calls.append((crop_id, farmer_profile_id))
        return self.crop


class FakeFarmBoundaryRepository:
    def __init__(self, boundary, geometry=GEOMETRY):
        self.boundary = boundary
        self.geometry = geometry
        self.boundary_calls = []
        self.geometry_calls = []

    def get_by_farm_id(self, farm_id):
        self.boundary_calls.append(farm_id)
        return self.boundary

    def get_geometry_as_geojson(self, boundary):
        self.geometry_calls.append(boundary)
        return self.geometry


class FakeProvider:
    def __init__(self, images=None, error=None):
        self.images = images or []
        self.error = error
        self.calls = []

    def search_images(
        self,
        geometry,
        start_date,
        end_date,
        max_cloud_percentage,
    ):
        self.calls.append(
            (geometry, start_date, end_date, max_cloud_percentage)
        )
        if self.error is not None:
            raise self.error
        return self.images


class FakeImageProcessor:
    def __init__(self, processed_image):
        self.processed_image = processed_image
        self.calls = []

    def process_image(self, image, geometry):
        self.calls.append((image, geometry))
        return self.processed_image


class FakeNdviProcessor:
    def __init__(self, ndvi_result):
        self.ndvi_result = ndvi_result
        self.calls = []

    def calculate_ndvi(self, processed_image):
        self.calls.append(processed_image)
        return self.ndvi_result


class FakeStatisticsProcessor:
    def __init__(self, mean_ndvi):
        self.mean_ndvi = mean_ndvi
        self.calls = []

    def calculate_mean(self, ndvi_result):
        self.calls.append(ndvi_result)
        return self.mean_ndvi


class FakeNdviPersistence:
    def __init__(self, observation, metric, error=None):
        self.observation = observation
        self.metric = metric
        self.error = error
        self.calls = []

    def persist_mean_ndvi(self, crop_id, image, mean_ndvi):
        self.calls.append((crop_id, image, mean_ndvi))
        if self.error is not None:
            raise self.error
        return self.observation, self.metric


class FakeAdvisoryPersistence:
    def __init__(self, persisted_advisory):
        self.persisted_advisory = persisted_advisory
        self.calls = []

    def persist(self, advisory, farm_id, crop_id, observation_id):
        self.calls.append((advisory, farm_id, crop_id, observation_id))
        return self.persisted_advisory


def _user():
    return SimpleNamespace(id=USER_ID)


def _profile():
    return SimpleNamespace(id=PROFILE_ID)


def _crop():
    return SimpleNamespace(id=CROP_ID, farm_id=FARM_ID)


def _boundary():
    return SimpleNamespace(id=BOUNDARY_ID)


def _image(image_id, acquisition_date):
    return SatelliteImage(
        image_id=image_id,
        acquisition_date=acquisition_date,
        cloud_percentage=5.0,
        provider="google_earth_engine",
        collection="COPERNICUS/S2_SR_HARMONIZED",
    )


def _collaborators(
    *,
    profile=None,
    crop=None,
    boundary=None,
    images=None,
    provider_error=None,
    ndvi_error=None,
):
    observation = CropObservation(
        id=OBSERVATION_ID,
        crop_id=CROP_ID,
        observation_date=date(2026, 10, 2),
        data_source="sentinel-2",
    )
    metric = HealthMetric(
        id=METRIC_ID,
        observation_id=OBSERVATION_ID,
        metric_name="ndvi_mean",
        metric_value=Decimal("0.75"),
        health_status="Great",
    )
    persisted_advisory = Advisory(
        id=ADVISORY_ID,
        farm_id=FARM_ID,
        crop_id=CROP_ID,
        observation_id=OBSERVATION_ID,
        title="Crop health looks good",
        message="Continue monitoring.",
        severity="Great",
        priority="low",
        category="crop_health",
    )
    provider = FakeProvider(images=images, error=provider_error)
    image_processor = FakeImageProcessor(SimpleNamespace(image_id="processed"))
    ndvi_processor = FakeNdviProcessor(SimpleNamespace(image_id="ndvi"))
    statistics_processor = FakeStatisticsProcessor(0.75)
    ndvi_persistence = FakeNdviPersistence(
        observation,
        metric,
        error=ndvi_error,
    )
    advisory_persistence = FakeAdvisoryPersistence(persisted_advisory)

    service = CropHealthAnalysisService.__new__(CropHealthAnalysisService)
    service.farmer_profile_repository = FakeFarmerProfileRepository(profile)
    service.crop_health_repository = FakeCropHealthRepository(crop)
    service.farm_boundary_repository = FakeFarmBoundaryRepository(boundary)
    service.provider = provider
    service.image_processor = image_processor
    service.ndvi_processor = ndvi_processor
    service.statistics_processor = statistics_processor
    service.ndvi_persistence = ndvi_persistence
    service.advisory_persistence = advisory_persistence
    return service, {
        "provider": provider,
        "image_processor": image_processor,
        "ndvi_processor": ndvi_processor,
        "statistics_processor": statistics_processor,
        "ndvi_persistence": ndvi_persistence,
        "advisory_persistence": advisory_persistence,
    }


def test_successful_analysis_orchestrates_and_returns_result():
    images = [
        _image("older", date(2026, 9, 20)),
        _image("latest", date(2026, 10, 1)),
    ]
    service, collaborators = _collaborators(
        profile=_profile(),
        crop=_crop(),
        boundary=_boundary(),
        images=images,
    )

    result = service.analyze_crop_health(_user(), CROP_ID, date(2026, 10, 2))

    assert isinstance(result, CropHealthAnalysisResult)
    assert result.crop_id == CROP_ID
    assert result.observation.id == OBSERVATION_ID
    assert result.metric.health_status == "Great"
    assert result.advisory.id == ADVISORY_ID
    assert collaborators["image_processor"].calls[0][0].image_id == "latest"
    assert collaborators["ndvi_processor"].calls
    assert collaborators["statistics_processor"].calls
    assert collaborators["ndvi_persistence"].calls == [
        (CROP_ID, images[1], 0.75)
    ]
    advisory_call = collaborators["advisory_persistence"].calls[0]
    assert advisory_call[0].status == "Great"
    assert advisory_call[1:] == (FARM_ID, CROP_ID, OBSERVATION_ID)


def test_uses_todays_date_by_default():
    service, collaborators = _collaborators(
        profile=_profile(),
        crop=_crop(),
        boundary=_boundary(),
        images=[_image("image", date.today())],
    )
    today = date.today()

    service.analyze_crop_health(_user(), CROP_ID)

    _, start_date, end_date, cloud_percentage = collaborators["provider"].calls[0]
    assert start_date == today - timedelta(days=DEFAULT_LOOKBACK_DAYS)
    assert end_date == today
    assert cloud_percentage == DEFAULT_MAX_CLOUD_PERCENTAGE


def test_uses_explicit_analysis_date():
    analysis_date = date(2026, 8, 15)
    service, collaborators = _collaborators(
        profile=_profile(),
        crop=_crop(),
        boundary=_boundary(),
        images=[_image("image", analysis_date)],
    )

    service.analyze_crop_health(_user(), CROP_ID, analysis_date)

    _, start_date, end_date, _ = collaborators["provider"].calls[0]
    assert start_date == date(2026, 7, 16)
    assert end_date == analysis_date


def test_selects_latest_image_with_image_id_tie_breaker():
    images = [
        _image("z-image", date(2026, 10, 1)),
        _image("a-image", date(2026, 10, 2)),
        _image("b-image", date(2026, 10, 2)),
        _image("older", date(2026, 9, 30)),
    ]
    service, collaborators = _collaborators(
        profile=_profile(),
        crop=_crop(),
        boundary=_boundary(),
        images=images,
    )

    service.analyze_crop_health(_user(), CROP_ID, date(2026, 10, 3))

    assert collaborators["image_processor"].calls[0][0].image_id == "b-image"


def test_missing_farmer_profile_stops_workflow():
    service, collaborators = _collaborators(profile=None)

    with pytest.raises(NotFoundException, match="Crop not found."):
        service.analyze_crop_health(_user(), CROP_ID)

    assert collaborators["provider"].calls == []
    assert collaborators["image_processor"].calls == []
    assert collaborators["ndvi_persistence"].calls == []


def test_inaccessible_crop_stops_before_boundary_and_gee():
    service, collaborators = _collaborators(
        profile=_profile(),
        crop=None,
    )

    with pytest.raises(NotFoundException, match="Crop not found."):
        service.analyze_crop_health(_user(), CROP_ID)

    assert collaborators["provider"].calls == []
    assert collaborators["image_processor"].calls == []


def test_missing_boundary_stops_before_gee():
    service, collaborators = _collaborators(
        profile=_profile(),
        crop=_crop(),
        boundary=None,
    )

    with pytest.raises(NotFoundException, match="Farm boundary not found."):
        service.analyze_crop_health(_user(), CROP_ID)

    assert collaborators["provider"].calls == []


def test_no_suitable_imagery_raises_and_does_not_persist():
    service, collaborators = _collaborators(
        profile=_profile(),
        crop=_crop(),
        boundary=_boundary(),
        images=[],
    )

    with pytest.raises(
        RemoteSensingProviderError,
        match="No suitable satellite image was found for this crop.",
    ):
        service.analyze_crop_health(_user(), CROP_ID)

    assert collaborators["image_processor"].calls == []
    assert collaborators["ndvi_persistence"].calls == []
    assert collaborators["advisory_persistence"].calls == []


def test_remote_sensing_error_propagates_unchanged():
    error = RemoteSensingProviderError("provider unavailable")
    service, collaborators = _collaborators(
        profile=_profile(),
        crop=_crop(),
        boundary=_boundary(),
        provider_error=error,
    )

    with pytest.raises(RemoteSensingProviderError) as raised:
        service.analyze_crop_health(_user(), CROP_ID)

    assert raised.value is error
    assert collaborators["image_processor"].calls == []


def test_ndvi_persistence_failure_skips_advisory_work():
    error = RuntimeError("persistence failed")
    service, collaborators = _collaborators(
        profile=_profile(),
        crop=_crop(),
        boundary=_boundary(),
        images=[_image("image", date(2026, 10, 1))],
        ndvi_error=error,
    )

    with pytest.raises(RuntimeError, match="persistence failed"):
        service.analyze_crop_health(_user(), CROP_ID)

    assert collaborators["advisory_persistence"].calls == []


def test_analysis_result_is_immutable():
    result = CropHealthAnalysisResult(
        crop_id=CROP_ID,
        observation=SimpleNamespace(),
        metric=SimpleNamespace(),
        advisory=SimpleNamespace(),
    )

    with pytest.raises(FrozenInstanceError):
        result.crop_id = UUID("00000000-0000-0000-0000-000000000009")
