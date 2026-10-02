from datetime import date
from decimal import Decimal
from uuid import UUID, uuid4

from sqlalchemy import select

from app.models.crop import Crop
from app.models.farm import Farm
from app.models.observation import CropObservation, HealthMetric
from app.models.user import FarmerProfile


def register_and_login(client, phone_number: str) -> tuple[dict, dict[str, str]]:
    registration = client.post(
        "/api/v1/auth/register",
        json={
            "phone_number": phone_number,
            "password": "TestPass123",
            "full_name": "Crop Trend Farmer",
        },
    )
    assert registration.status_code == 201

    login = client.post(
        "/api/v1/auth/login",
        json={"phone_number": phone_number, "password": "TestPass123"},
    )
    assert login.status_code == 200
    return registration.json(), {
        "Authorization": f"Bearer {login.json()['access_token']}"
    }


def create_crop(db_session, user_id: str) -> Crop:
    profile = db_session.scalar(
        select(FarmerProfile).where(FarmerProfile.user_id == UUID(user_id))
    )
    assert profile is not None
    farm = Farm(id=uuid4(), farmer_id=profile.id, name="Trend Farm")
    crop = Crop(
        id=uuid4(),
        farm_id=farm.id,
        crop_name="Wheat",
        season="rabi",
    )
    db_session.add_all([farm, crop])
    db_session.commit()
    return crop


def create_observation(
    db_session,
    crop_id,
    observation_date: date,
    ndvi_mean: Decimal,
    health_status: str,
) -> None:
    observation = CropObservation(
        id=uuid4(),
        crop_id=crop_id,
        observation_date=observation_date,
        data_source="sentinel-2",
        cloud_percentage=Decimal("8.25"),
    )
    db_session.add(observation)
    db_session.flush()
    db_session.add(
        HealthMetric(
            id=uuid4(),
            observation_id=observation.id,
            metric_name="ndvi_mean",
            metric_value=ndvi_mean,
            health_status=health_status,
        )
    )
    db_session.commit()


def test_authenticated_farmer_retrieves_improving_trend(
    client,
    db_session,
):
    user, headers = register_and_login(client, "9900000001")
    crop = create_crop(db_session, user["id"])
    create_observation(
        db_session,
        crop.id,
        date(2026, 9, 1),
        Decimal("0.200000"),
        "Bad",
    )
    create_observation(
        db_session,
        crop.id,
        date(2026, 10, 1),
        Decimal("0.800000"),
        "Great",
    )

    response = client.get(
        f"/api/v1/crops/{crop.id}/health/trend",
        headers=headers,
    )

    assert response.status_code == 200
    assert response.json() == {
        "crop_id": str(crop.id),
        "trend": {
            "direction": "Improving",
            "first_ndvi": "0.200000",
            "latest_ndvi": "0.800000",
            "change": "0.600000",
            "observation_count": 2,
        },
    }


def test_declining_trend_is_returned(client, db_session):
    user, headers = register_and_login(client, "9900000002")
    crop = create_crop(db_session, user["id"])
    create_observation(
        db_session,
        crop.id,
        date(2026, 9, 1),
        Decimal("0.800000"),
        "Great",
    )
    create_observation(
        db_session,
        crop.id,
        date(2026, 10, 1),
        Decimal("0.200000"),
        "Bad",
    )

    response = client.get(
        f"/api/v1/crops/{crop.id}/health/trend",
        headers=headers,
    )

    assert response.status_code == 200
    assert response.json()["trend"]["direction"] == "Declining"


def test_stable_trend_is_returned(client, db_session):
    user, headers = register_and_login(client, "9900000003")
    crop = create_crop(db_session, user["id"])
    create_observation(
        db_session,
        crop.id,
        date(2026, 9, 1),
        Decimal("0.400000"),
        "Good",
    )
    create_observation(
        db_session,
        crop.id,
        date(2026, 10, 1),
        Decimal("0.440000"),
        "Good",
    )

    response = client.get(
        f"/api/v1/crops/{crop.id}/health/trend",
        headers=headers,
    )

    assert response.status_code == 200
    assert response.json()["trend"]["direction"] == "Stable"



def test_newest_first_history_is_interpreted_chronologically(client, db_session):
    user, headers = register_and_login(client, "9900000007")
    crop = create_crop(db_session, user["id"])

    # Insert chronologically, but the repository returns these newest first.
    create_observation(
        db_session,
        crop.id,
        date(2026, 9, 1),
        Decimal("0.200000"),
        "Bad",
    )
    create_observation(
        db_session,
        crop.id,
        date(2026, 10, 1),
        Decimal("0.800000"),
        "Great",
    )

    response = client.get(
        f"/api/v1/crops/{crop.id}/health/trend",
        headers=headers,
    )

    assert response.status_code == 200
    assert response.json()["trend"] == {
        "direction": "Improving",
        "first_ndvi": "0.200000",
        "latest_ndvi": "0.800000",
        "change": "0.600000",
        "observation_count": 2,
    }


def test_fewer_than_two_observations_returns_bad_request(client, db_session):
    user, headers = register_and_login(client, "9900000004")
    crop = create_crop(db_session, user["id"])
    create_observation(
        db_session,
        crop.id,
        date(2026, 10, 1),
        Decimal("0.400000"),
        "Good",
    )

    response = client.get(
        f"/api/v1/crops/{crop.id}/health/trend",
        headers=headers,
    )

    assert response.status_code == 400
    assert response.json()["detail"] == (
        "At least two NDVI observations are required."
    )


def test_another_farmers_crop_returns_not_found(client, db_session):
    owner, _ = register_and_login(client, "9900000005")
    _, other_headers = register_and_login(client, "9900000006")
    crop = create_crop(db_session, owner["id"])

    response = client.get(
        f"/api/v1/crops/{crop.id}/health/trend",
        headers=other_headers,
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Crop not found."


def test_unauthenticated_trend_request_returns_401(client):
    response = client.get(f"/api/v1/crops/{uuid4()}/health/trend")

    assert response.status_code == 401
