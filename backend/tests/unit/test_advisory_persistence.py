from uuid import uuid4

import pytest
from sqlalchemy.exc import SQLAlchemyError

from app.advisory import generate_advisory
from app.models.advisory import Advisory
from app.repositories.advisory import AdvisoryRepository
from app.services.advisory_persistence import AdvisoryPersistenceService


class FakeRepository:
    def __init__(self):
        self.created = None
        self.committed = False
        self.rolled_back = False

    def create(self, advisory):
        advisory.id = uuid4()
        advisory.is_read = False
        self.created = advisory
        return advisory

    def commit(self):
        self.committed = True

    def refresh(self, advisory):
        return None

    def rollback(self):
        self.rolled_back = True


def _service(repository):
    service = AdvisoryPersistenceService.__new__(AdvisoryPersistenceService)
    service.repository = repository
    return service


@pytest.mark.parametrize(
    ("status", "priority"),
    [("Great", "low"), ("Good", "low"), ("Bad", "medium"), ("Severe", "high")],
)
def test_persists_domain_advisory(status, priority):
    repository = FakeRepository()
    farm_id, crop_id, observation_id = uuid4(), uuid4(), uuid4()

    result = _service(repository).persist(
        generate_advisory(status),
        farm_id,
        crop_id,
        observation_id,
    )

    assert result.farm_id == farm_id
    assert result.crop_id == crop_id
    assert result.observation_id == observation_id
    assert result.severity == status
    assert result.priority == priority
    assert result.title == generate_advisory(status).title
    assert result.message == generate_advisory(status).message
    assert result.category == "crop_health"
    assert result.is_read is False
    assert result.expires_at is None
    assert repository.committed is True


class FailingRepository(FakeRepository):
    def create(self, advisory):
        raise SQLAlchemyError("insert failed")


def test_database_error_rolls_back_and_reraises():
    repository = FailingRepository()

    with pytest.raises(SQLAlchemyError, match="insert failed"):
        _service(repository).persist(
            generate_advisory("Good"),
            uuid4(),
            uuid4(),
            uuid4(),
        )

    assert repository.rolled_back is True
    assert repository.committed is False
