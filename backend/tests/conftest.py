import os

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.orm import sessionmaker

from app.database.base import Base
from app.database.session import get_db
from app.main import app


TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+psycopg://rajghule@localhost:5432/krushimitra_test",
)

test_engine = create_engine(
    TEST_DATABASE_URL,
    pool_pre_ping=True,
)

TestingSessionLocal = sessionmaker(
    bind=test_engine,
    autocommit=False,
    autoflush=False,
)


@pytest.fixture(scope="session", autouse=True)
def reset_test_database() -> None:
    """Clear application data once before the test session begins."""
    database_name = make_url(TEST_DATABASE_URL).database
    if database_name != "krushimitra_test":
        raise RuntimeError(
            "Refusing to reset a database other than krushimitra_test."
        )

    with test_engine.begin() as connection:
        connection.execute(
            text(
                """
                TRUNCATE TABLE
                    users,
                    farmer_profiles,
                    farms,
                    farm_boundaries,
                    crops,
                    crop_observations,
                    health_metrics,
                    advisories,
                    notifications
                RESTART IDENTITY CASCADE
                """
            )
        )


@pytest.fixture
def db_session():
    session = TestingSessionLocal()

    try:
        yield session
    finally:
        session.rollback()
        session.close()


@pytest.fixture
def client():
    def override_get_db():
        session = TestingSessionLocal()

        try:
            yield session
        finally:
            session.close()

    app.dependency_overrides[get_db] = override_get_db

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()
