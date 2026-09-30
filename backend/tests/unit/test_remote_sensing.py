from datetime import date
from typing import Any, Mapping

import pytest
from pydantic import ValidationError

from app.remote_sensing import (
    RemoteSensingAuthenticationError,
    RemoteSensingError,
    RemoteSensingProvider,
    RemoteSensingProviderError,
    RemoteSensingUnavailableError,
    SatelliteImage,
)


def test_satellite_image_accepts_valid_metadata() -> None:
    image = SatelliteImage(
        image_id="image-1",
        acquisition_date=date(2026, 9, 30),
        cloud_percentage=12.5,
        provider="example",
        collection="surface-reflectance",
    )

    assert image.image_id == "image-1"
    assert image.acquisition_date == date(2026, 9, 30)


@pytest.mark.parametrize("cloud_percentage", [0, 100])
def test_satellite_image_accepts_cloud_percentage_boundaries(
    cloud_percentage: float,
) -> None:
    image = SatelliteImage(
        image_id="image-1",
        acquisition_date=date(2026, 9, 30),
        cloud_percentage=cloud_percentage,
        provider="example",
    )

    assert image.cloud_percentage == cloud_percentage


@pytest.mark.parametrize("cloud_percentage", [-0.01, 100.01])
def test_satellite_image_rejects_invalid_cloud_percentage(
    cloud_percentage: float,
) -> None:
    with pytest.raises(ValidationError):
        SatelliteImage(
            image_id="image-1",
            acquisition_date=date(2026, 9, 30),
            cloud_percentage=cloud_percentage,
            provider="example",
        )


class FakeRemoteSensingProvider(RemoteSensingProvider):
    def _search_images(
        self,
        geometry: Mapping[str, Any],
        start_date: date,
        end_date: date,
        max_cloud_percentage: float | None = None,
    ) -> list[SatelliteImage]:
        return [
            SatelliteImage(
                image_id="image-1",
                acquisition_date=start_date,
                cloud_percentage=max_cloud_percentage,
                provider="fake",
            )
        ]


def test_provider_returns_normalized_satellite_images() -> None:
    provider = FakeRemoteSensingProvider()

    images = provider.search_images(
        geometry={"type": "Polygon", "coordinates": []},
        start_date=date(2026, 9, 1),
        end_date=date(2026, 9, 30),
        max_cloud_percentage=25,
    )

    assert len(images) == 1
    assert isinstance(images[0], SatelliteImage)
    assert images[0].provider == "fake"


def test_provider_rejects_an_invalid_date_range() -> None:
    provider = FakeRemoteSensingProvider()

    with pytest.raises(ValueError, match="start_date"):
        provider.search_images(
            geometry={},
            start_date=date(2026, 10, 1),
            end_date=date(2026, 9, 30),
        )


@pytest.mark.parametrize("cloud_percentage", [-1, 101])
def test_provider_rejects_invalid_cloud_filter(cloud_percentage: float) -> None:
    provider = FakeRemoteSensingProvider()

    with pytest.raises(ValueError, match="max_cloud_percentage"):
        provider.search_images(
            geometry={},
            start_date=date(2026, 9, 1),
            end_date=date(2026, 9, 30),
            max_cloud_percentage=cloud_percentage,
        )


def test_provider_is_abstract() -> None:
    with pytest.raises(TypeError):
        RemoteSensingProvider()


def test_remote_sensing_exception_hierarchy() -> None:
    assert issubclass(RemoteSensingProviderError, RemoteSensingError)
    assert issubclass(RemoteSensingAuthenticationError, RemoteSensingProviderError)
    assert issubclass(RemoteSensingUnavailableError, RemoteSensingProviderError)
