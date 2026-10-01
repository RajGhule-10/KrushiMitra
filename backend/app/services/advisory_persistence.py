from uuid import UUID

from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.advisory import Advisory as DomainAdvisory
from app.models.advisory import Advisory
from app.repositories.advisory import AdvisoryRepository


class AdvisoryPersistenceService:
    """Persist a generated domain advisory for a crop observation."""

    def __init__(self, db: Session) -> None:
        self.repository = AdvisoryRepository(db)

    def persist(
        self,
        advisory: DomainAdvisory,
        farm_id: UUID,
        crop_id: UUID,
        observation_id: UUID,
    ) -> Advisory:
        persisted = Advisory(
            farm_id=farm_id,
            crop_id=crop_id,
            observation_id=observation_id,
            title=advisory.title,
            message=advisory.message,
            severity=advisory.status,
            priority=advisory.priority,
            category="crop_health",
            expires_at=None,
        )
        try:
            self.repository.create(persisted)
            self.repository.commit()
            self.repository.refresh(persisted)
        except SQLAlchemyError:
            self.repository.rollback()
            raise
        return persisted
