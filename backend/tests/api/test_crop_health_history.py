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
            "full_name": "Crop History Farmer",
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
    farm = Farm(id=uuid4(), farmer_id=profile.id, name="History Farm")
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
    cloud_percentage: Decimal | None = Decimal("8.25"),
) -> CropObservation:
    observation = CropObservation(
        id=uuid4(),
        crop_id=crop_id,
        observation_date=observation_date,
        data_source="sentinel-2",
        cloud_percentage=cloud_percentage,
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
    return observation


def test_authenticated_farmer_retrieves_crop_health_history(
    client,
    db_session,
):
    user, headers = register_and_login(client, "9800000001")
    crop = create_crop(db_session, user["id"])
    create_observation(
        db_session,
        crop.id,
        date(2026, 9, 2),
        Decimal("0.350000"),
        "Bad",
        None,
    )
    create_observation(
        db_session,
        crop.id,
        date(2026, 10, 2),
        Decimal("0.750000"),
        "Great",
    )

    response = client.get(
        f"/api/v1/crops/{crop.id}/health/history",
        headers=headers,
    )

    assert response.status_code == 200
    assert response.json() == {
        "crop_id": str(crop.id),
        "history": [
            {
                "observation_date": "2026-10-02",
                "data_source": "sentinel-2",
                "cloud_percentage": "8.25",
                "ndvi_mean": "0.750000",
                "health_status": "Great",
            },
            {
                "observation_date": "2026-09-02",
                "data_source": "sentinel-2",
                "cloud_percentage": None,
                "ndvi_mean": "0.350000",
                "health_status": "Bad",
            },
        ],
    }


def test_crop_without_health_history_returns_empty_list(client, db_session):
    user, headers = register_and_login(client, "9800000002")
    crop = create_crop(db_session, user["id"])

    response = client.get(
        f"/api/v1/crops/{crop.id}/health/history",
        headers=headers,
    )

    assert response.status_code == 200
    assert response.json() == {
        "crop_id": str(crop.id),
        "history": [],
    }


def test_another_farmers_crop_returns_not_found(client, db_session):
    owner, _ = register_and_login(client, "9800000003")
    _, other_headers = register_and_login(client, "9800000004")
    crop = create_crop(db_session, owner["id"])

    response = client.get(
        f"/api/v1/crops/{crop.id}/health/history",
        headers=other_headers,
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Crop not found."


def test_unauthenticated_history_request_returns_401(client):
    response = client.get(f"/api/v1/crops/{uuid4()}/health/history")

    assert response.status_code == 401
