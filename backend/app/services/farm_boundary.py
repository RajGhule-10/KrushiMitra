from uuid import UUID

from fastapi import HTTPException, status
from geoalchemy2.elements import WKTElement
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.core.errors import NotFoundException
from app.models.farm import Farm, FarmBoundary
from app.models.user import User
from app.repositories.farm import FarmRepository
from app.repositories.farm_boundary import FarmBoundaryRepository
from app.repositories.farmer_profile import FarmerProfileRepository
from app.schemas.farm_boundary import (
    FarmBoundaryResponse,
    GeometryRequest,
    MultiPolygonGeometry,
    MultiPolygonGeometryResponse,
    PolygonGeometry,
)


class FarmBoundaryService:
    """Boundary operations scoped to farms owned by the authenticated farmer."""

    def __init__(self, db: Session) -> None:
        self.farm_repository = FarmRepository(db)
        self.boundary_repository = FarmBoundaryRepository(db)
        self.farmer_profile_repository = FarmerProfileRepository(db)

    def put_boundary(
        self,
        current_user: User,
        farm_id: UUID,
        geometry: GeometryRequest,
    ) -> FarmBoundaryResponse:
        farm = self._get_owned_farm(current_user, farm_id)
        normalized_geometry = self._normalize_geometry(geometry)
        wkt_geometry = WKTElement(
            self._multi_polygon_to_wkt(normalized_geometry.coordinates),
            srid=4326,
        )

        if not self.boundary_repository.is_valid_geometry(wkt_geometry):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail="Geometry is not valid.",
            )

        boundary = self.boundary_repository.get_by_farm_id(farm.id)
        if boundary is None:
            boundary = FarmBoundary(farm_id=farm.id, geometry=wkt_geometry)
            self.boundary_repository.create(boundary)
        else:
            self.boundary_repository.replace_geometry(boundary, wkt_geometry)

        try:
            self.boundary_repository.commit()
            self.boundary_repository.refresh(boundary)
        except SQLAlchemyError:
            self.boundary_repository.rollback()
            raise

        return FarmBoundaryResponse(
            farm_id=farm.id,
            geometry=normalized_geometry,
        )

    def get_boundary(
        self,
        current_user: User,
        farm_id: UUID,
    ) -> FarmBoundaryResponse:
        farm = self._get_owned_farm(current_user, farm_id)
        boundary = self.boundary_repository.get_by_farm_id(farm.id)
        if boundary is None:
            raise NotFoundException("Farm boundary not found.")

        geometry = self.boundary_repository.get_geometry_as_geojson(boundary)
        return FarmBoundaryResponse(
            farm_id=farm.id,
            geometry=MultiPolygonGeometryResponse.model_validate(geometry),
        )

    def _get_owned_farm(self, current_user: User, farm_id: UUID) -> Farm:
        profile = self.farmer_profile_repository.get_by_user_id(current_user.id)
        if profile is None:
            raise NotFoundException("Farmer profile not found.")

        farm = self.farm_repository.get_by_id_for_farmer(farm_id, profile.id)
        if farm is None:
            raise NotFoundException("Farm not found.")
        return farm

    @staticmethod
    def _normalize_geometry(geometry: GeometryRequest) -> MultiPolygonGeometryResponse:
        if isinstance(geometry, PolygonGeometry):
            coordinates = [geometry.coordinates]
        else:
            coordinates = geometry.coordinates
        return MultiPolygonGeometryResponse(coordinates=coordinates)

    @staticmethod
    def _multi_polygon_to_wkt(coordinates: list[list[list[tuple[float, float]]]]) -> str:
        polygons = []
        for polygon in coordinates:
            rings = []
            for ring in polygon:
                positions = ", ".join(
                    f"{longitude:.15g} {latitude:.15g}"
                    for longitude, latitude in ring
                )
                rings.append(f"({positions})")
            polygons.append(f"({', '.join(rings)})")
        return f"MULTIPOLYGON({', '.join(polygons)})"
