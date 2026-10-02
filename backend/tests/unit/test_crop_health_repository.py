from datetime import date, datetime, timezone
from uuid import UUID

from sqlalchemy.dialects import postgresql

from app.models.observation import CropObservation, HealthMetric
from app.repositories.crop_health import CropHealthRepository


CROP_ID = UUID("00000000-0000-0000-0000-000000000001")
FARMER_PROFILE_ID = UUID("00000000-0000-0000-0000-000000000002")


class ScalarResult:
    def __init__(self, rows):
        self.rows = rows

    def all(self):
        return self.rows


class FakeSession:
    def __init__(self, rows):
        self.rows = rows
        self.statement = None

    def execute(self, statement):
        self.statement = statement
        return ScalarResult(self.rows)


def _observation(observation_id, observation_date, created_at):
    return CropObservation(
        id=observation_id,
        crop_id=CROP_ID,
        observation_date=observation_date,
        created_at=created_at,
        data_source="sentinel-2",
    )


def _metric(observation_id, metric_name="ndvi_mean"):
    return HealthMetric(
        observation_id=observation_id,
        metric_name=metric_name,
        metric_value="0.420000",
        health_status="Good",
    )


def _repository(rows):
    session = FakeSession(rows)
    return CropHealthRepository(session), session


def _sql(session):
    return str(
        session.statement.compile(
            dialect=postgresql.dialect(),
            compile_kwargs={"literal_binds": True},
        )
    )


def test_owned_crop_returns_observation_and_ndvi_metric_pairs():
    observation = _observation(
        UUID("00000000-0000-0000-0000-000000000003"),
        date(2026, 10, 2),
        datetime(2026, 10, 2, tzinfo=timezone.utc),
    )
    metric = _metric(observation.id)
    repository, session = _repository([(observation, metric)])

    result = repository.get_health_history_for_crop(
        CROP_ID,
        FARMER_PROFILE_ID,
    )

    assert result == [(observation, metric)]
    assert f"crop_observations.crop_id = '{CROP_ID}'" in _sql(session)
    assert f"farms.farmer_id = '{FARMER_PROFILE_ID}'" in _sql(session)


def test_multiple_observations_are_returned_newest_first():
    newest = _observation(
        UUID("00000000-0000-0000-0000-000000000003"),
        date(2026, 10, 2),
        datetime(2026, 10, 2, tzinfo=timezone.utc),
    )
    older = _observation(
        UUID("00000000-0000-0000-0000-000000000004"),
        date(2026, 9, 2),
        datetime(2026, 9, 2, tzinfo=timezone.utc),
    )
    repository, session = _repository(
        [(newest, _metric(newest.id)), (older, _metric(older.id))]
    )

    result = repository.get_health_history_for_crop(
        CROP_ID,
        FARMER_PROFILE_ID,
    )

    assert [observation.id for observation, _ in result] == [
        newest.id,
        older.id,
    ]
    query = _sql(session)
    assert "crop_observations.observation_date DESC" in query
    assert "crop_observations.created_at DESC" in query
    assert "crop_observations.id DESC" in query


def test_non_ndvi_health_metrics_are_excluded():
    repository, session = _repository([])

    assert (
        repository.get_health_history_for_crop(
            CROP_ID,
            FARMER_PROFILE_ID,
        )
        == []
    )
    assert "health_metrics.metric_name = 'ndvi_mean'" in _sql(session)


def test_another_farmers_crop_returns_empty_list():
    repository, session = _repository([])

    result = repository.get_health_history_for_crop(
        CROP_ID,
        FARMER_PROFILE_ID,
    )

    assert result == []
    assert "farms.farmer_id" in _sql(session)


def test_crop_with_no_observations_returns_empty_list():
    repository, _ = _repository([])

    assert (
        repository.get_health_history_for_crop(
            CROP_ID,
            FARMER_PROFILE_ID,
        )
        == []
    )
