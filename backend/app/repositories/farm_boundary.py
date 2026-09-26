import json
from uuid import UUID

from geoalchemy2.elements import WKTElement
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.farm import FarmBoundary


class FarmBoundaryRepository:
    """Database access for farm boundaries."""

    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_farm_id(self, farm_id: UUID) -> FarmBoundary | None:
        statement = select(FarmBoundary).where(FarmBoundary.farm_id == farm_id)
        return self.db.scalar(statement)

    def create(self, boundary: FarmBoundary) -> FarmBoundary:
        self.db.add(boundary)
        self.db.flush()
        return boundary

    def replace_geometry(
        self,
        boundary: FarmBoundary,
        geometry: WKTElement,
    ) -> FarmBoundary:
        boundary.geometry = geometry
        return boundary

    def is_valid_geometry(self, geometry: WKTElement) -> bool:
        return bool(self.db.scalar(select(func.ST_IsValid(geometry))))

    def get_geometry_as_geojson(self, boundary: FarmBoundary) -> dict[str, object]:
        statement = select(func.ST_AsGeoJSON(FarmBoundary.geometry)).where(
            FarmBoundary.id == boundary.id
        )
        geometry = self.db.scalar(statement)
        return json.loads(geometry)

    def commit(self) -> None:
        self.db.commit()

    def refresh(self, boundary: FarmBoundary) -> None:
        self.db.refresh(boundary)

    def rollback(self) -> None:
        self.db.rollback()
