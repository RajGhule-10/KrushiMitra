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
            "full_name": "Crop Health Farmer",
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


def create_crop(db_session, user_id: str, crop_name: str = "Wheat") -> Crop:
    profile = db_session.scalar(
        select(FarmerProfile).where(FarmerProfile.user_id == UUID(user_id))
    )
    assert profile is not None
    farm = Farm(id=uuid4(), farmer_id=profile.id, name="Health Farm")
    crop = Crop(
        id=uuid4(),
        farm_id=farm.id,
        crop_name=crop_name,
        season="rabi",
    )
    db_session.add_all([farm, crop])
    db_session.commit()
    return crop


def create_observation(
    db_session,
    crop_id,
    observation_date: date,
    cloud_percentage: Decimal | None = Decimal("8.25"),
    ndvi_mean: Decimal | None = Decimal("0.420000"),
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
    if ndvi_mean is not None:
        db_session.add(
            HealthMetric(
                id=uuid4(),
                observation_id=observation.id,
                metric_name="ndvi_mean",
                metric_value=ndvi_mean,
                health_status=None,
            )
        )
    db_session.commit()
    return observation


def test_farmer_retrieves_latest_health_for_owned_crop(client, db_session):
    user, headers = register_and_login(client, "9500000001")
    crop = create_crop(db_session, user["id"])
    create_observation(db_session, crop.id, date(2026, 10, 1))

    response = client.get(f"/api/v1/crops/{crop.id}/health", headers=headers)

    assert response.status_code == 200
    assert response.json() == {
        "crop_id": str(crop.id),
        "crop_name": "Wheat",
        "latest_observation": {
            "observation_date": "2026-10-01",
            "data_source": "sentinel-2",
            "cloud_percentage": "8.25",
            "ndvi_mean": "0.420000",
        },
    }


def test_latest_observation_is_returned_over_older_observation(client, db_session):
    user, headers = register_and_login(client, "9500000002")
    crop = create_crop(db_session, user["id"])
    create_observation(
        db_session,
        crop.id,
        date(2026, 9, 1),
        ndvi_mean=Decimal("0.100000"),
    )
    create_observation(
        db_session,
        crop.id,
        date(2026, 10, 1),
        ndvi_mean=Decimal("0.800000"),
    )

    response = client.get(f"/api/v1/crops/{crop.id}/health", headers=headers)

    assert response.status_code == 200
    assert response.json()["latest_observation"]["observation_date"] == "2026-10-01"
    assert response.json()["latest_observation"]["ndvi_mean"] == "0.800000"


def test_crop_without_observations_returns_null_health(client, db_session):
    user, headers = register_and_login(client, "9500000003")
    crop = create_crop(db_session, user["id"])

    response = client.get(f"/api/v1/crops/{crop.id}/health", headers=headers)

    assert response.status_code == 200
    assert response.json()["crop_id"] == str(crop.id)
    assert response.json()["crop_name"] == "Wheat"
    assert response.json()["latest_observation"] is None


def test_farmer_cannot_retrieve_another_farmers_crop_health(client, db_session):
    owner, _ = register_and_login(client, "9500000004")
    _, other_headers = register_and_login(client, "9500000005")
    crop = create_crop(db_session, owner["id"])

    response = client.get(f"/api/v1/crops/{crop.id}/health", headers=other_headers)

    assert response.status_code == 404
    assert response.json()["detail"] == "Crop not found."


def test_nonexistent_crop_returns_not_found(client):
    _, headers = register_and_login(client, "9500000006")

    response = client.get(f"/api/v1/crops/{uuid4()}/health", headers=headers)

    assert response.status_code == 404
    assert response.json()["detail"] == "Crop not found."


def test_unauthenticated_crop_health_request_is_rejected(client):
    response = client.get(f"/api/v1/crops/{uuid4()}/health")

    assert response.status_code == 401


def test_observation_without_ndvi_mean_returns_null_health(client, db_session):
    user, headers = register_and_login(client, "9500000007")
    crop = create_crop(db_session, user["id"])
    create_observation(db_session, crop.id, date(2026, 10, 1), ndvi_mean=None)

    response = client.get(f"/api/v1/crops/{crop.id}/health", headers=headers)

    assert response.status_code == 200
    assert response.json()["latest_observation"] is None
