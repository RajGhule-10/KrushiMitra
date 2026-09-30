from abc import ABC, abstractmethod
from datetime import date
from typing import Any, Mapping

from .models import SatelliteImage


class RemoteSensingProvider(ABC):
    """Provider-independent interface for searching satellite imagery.

    ``geometry`` is a GeoJSON-like mapping representing the area of interest.
    Its coordinate arrays must use GeoJSON ``[longitude, latitude]`` ordering.
    The farm-boundary schema remains responsible for validating API geometry;
    providers translate this representation into their own geometry types.
    """

    def search_images(
        self,
        geometry: Mapping[str, Any],
        start_date: date,
        end_date: date,
        max_cloud_percentage: float | None = None,
    ) -> list[SatelliteImage]:
        """Search imagery after validating the provider-independent request."""
        self.validate_search_request(
            start_date=start_date,
            end_date=end_date,
            max_cloud_percentage=max_cloud_percentage,
        )
        return self._search_images(
            geometry=geometry,
            start_date=start_date,
            end_date=end_date,
            max_cloud_percentage=max_cloud_percentage,
        )

    @staticmethod
    def validate_search_request(
        *,
        start_date: date,
        end_date: date,
        max_cloud_percentage: float | None = None,
    ) -> None:
        if start_date > end_date:
            raise ValueError("start_date must be on or before end_date.")
        if max_cloud_percentage is not None and not 0 <= max_cloud_percentage <= 100:
            raise ValueError("max_cloud_percentage must be between 0 and 100.")

    @abstractmethod
    def _search_images(
        self,
        geometry: Mapping[str, Any],
        start_date: date,
        end_date: date,
        max_cloud_percentage: float | None = None,
    ) -> list[SatelliteImage]:
        """Search a provider and return normalized image metadata."""
