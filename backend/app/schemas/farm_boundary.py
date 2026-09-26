import math
from typing import Annotated, Literal
from uuid import UUID

from pydantic import AfterValidator, BaseModel, Field, field_validator


def validate_position(value: tuple[float, float]) -> tuple[float, float]:
    longitude, latitude = value
    if not math.isfinite(longitude) or not math.isfinite(latitude):
        raise ValueError("Coordinates must be finite numbers.")
    if not -180 <= longitude <= 180:
        raise ValueError("Longitude must be between -180 and 180.")
    if not -90 <= latitude <= 90:
        raise ValueError("Latitude must be between -90 and 90.")
    return value


Position = Annotated[tuple[float, float], AfterValidator(validate_position)]
PolygonCoordinates = list[list[Position]]
MultiPolygonCoordinates = list[PolygonCoordinates]


def validate_ring(ring: list[Position]) -> None:
    if len(ring) < 4:
        raise ValueError("Each linear ring must contain at least four positions.")
    if ring[0] != ring[-1]:
        raise ValueError("Each linear ring must be closed.")
    if len(set(ring[:-1])) < 3:
        raise ValueError("Each linear ring must contain three distinct positions.")


def validate_polygon_coordinates(coordinates: PolygonCoordinates) -> PolygonCoordinates:
    if not coordinates:
        raise ValueError("Polygon coordinates cannot be empty.")
    for ring in coordinates:
        validate_ring(ring)
    return coordinates


class PolygonGeometry(BaseModel):
    type: Literal["Polygon"]
    coordinates: PolygonCoordinates

    @field_validator("coordinates")
    @classmethod
    def validate_coordinates(cls, value: PolygonCoordinates) -> PolygonCoordinates:
        return validate_polygon_coordinates(value)


class MultiPolygonGeometry(BaseModel):
    type: Literal["MultiPolygon"]
    coordinates: MultiPolygonCoordinates

    @field_validator("coordinates")
    @classmethod
    def validate_coordinates(
        cls,
        value: MultiPolygonCoordinates,
    ) -> MultiPolygonCoordinates:
        if not value:
            raise ValueError("MultiPolygon coordinates cannot be empty.")
        for polygon in value:
            validate_polygon_coordinates(polygon)
        return value


GeometryRequest = Annotated[
    PolygonGeometry | MultiPolygonGeometry,
    Field(discriminator="type"),
]


class MultiPolygonGeometryResponse(BaseModel):
    type: Literal["MultiPolygon"] = "MultiPolygon"
    coordinates: MultiPolygonCoordinates


class FarmBoundaryResponse(BaseModel):
    farm_id: UUID
    geometry: MultiPolygonGeometryResponse
