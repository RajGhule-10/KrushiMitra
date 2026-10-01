from sqlalchemy.orm import Session

from app.models.advisory import Advisory


class AdvisoryRepository:
    """Database access for persisted crop advisories."""

    def __init__(self, db: Session) -> None:
        self.db = db

    def create(self, advisory: Advisory) -> Advisory:
        self.db.add(advisory)
        self.db.flush()
        return advisory

    def commit(self) -> None:
        self.db.commit()

    def refresh(self, advisory: Advisory) -> None:
        self.db.refresh(advisory)

    def rollback(self) -> None:
        self.db.rollback()
