from datetime import date, datetime, timezone
from uuid import UUID, uuid4

from sqlalchemy import select

from app.models.advisory import Advisory
from app.models.crop import Crop
from app.models.farm import Farm
from app.models.observation import CropObservation
from app.models.user import FarmerProfile


def register_and_login(client, phone_number: str) -> tuple[dict, dict[str, str]]:
    registration = client.post(
        "/api/v1/auth/register",
        json={
            "phone_number": phone_number,
            "password": "TestPass123",
            "full_name": "Advisory Test Farmer",
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

    farm = Farm(id=uuid4(), farmer_id=profile.id, name="Advisory Farm")
    crop = Crop(
        id=uuid4(),
        farm_id=farm.id,
        crop_name=crop_name,
        season="rabi",
    )
    db_session.add_all([farm, crop])
    db_session.commit()
    return crop


def create_advisory(
    db_session,
    crop: Crop,
    *,
    created_at: datetime,
    title: str = "Crop health looks good",
    message: str = "Current vegetation indicators show healthy crop growth.",
    severity: str = "Great",
    priority: str = "low",
    category: str = "crop_health",
    is_read: bool = False,
    expires_at: datetime | None = None,
) -> Advisory:
    observation = CropObservation(
        id=uuid4(),
        crop_id=crop.id,
        observation_date=created_at.date(),
        data_source="sentinel-2",
    )
    advisory = Advisory(
        id=uuid4(),
        farm_id=crop.farm_id,
        crop_id=crop.id,
        observation_id=observation.id,
        title=title,
        message=message,
        severity=severity,
        priority=priority,
        category=category,
        is_read=is_read,
        created_at=created_at,
        expires_at=expires_at,
    )
    db_session.add(observation)
    db_session.flush()
    db_session.add(advisory)
    db_session.commit()
    return advisory


def test_authenticated_farmer_retrieves_existing_advisory(client, db_session):
    user, headers = register_and_login(client, "9600000001")
    crop = create_crop(db_session, user["id"])
    created_at = datetime(2026, 10, 1, 8, 30, tzinfo=timezone.utc)
    expires_at = datetime(2026, 10, 8, 8, 30, tzinfo=timezone.utc)
    advisory = create_advisory(
        db_session,
        crop,
        created_at=created_at,
        title="Possible crop stress detected",
        message="Inspect the field for possible causes.",
        severity="Bad",
        priority="medium",
        is_read=True,
        expires_at=expires_at,
    )

    response = client.get(
        f"/api/v1/crops/{crop.id}/advisory",
        headers=headers,
    )

    assert response.status_code == 200
    result = response.json()
    assert result["crop_id"] == str(crop.id)
    assert result["advisory"] == {
        "id": str(advisory.id),
        "crop_id": str(crop.id),
        "observation_id": str(advisory.observation_id),
        "title": "Possible crop stress detected",
        "message": "Inspect the field for possible causes.",
        "severity": "Bad",
        "priority": "medium",
        "category": "crop_health",
        "is_read": True,
        "created_at": result["advisory"]["created_at"],
        "expires_at": result["advisory"]["expires_at"],
    }
    assert datetime.fromisoformat(result["advisory"]["created_at"]) == created_at
    assert datetime.fromisoformat(result["advisory"]["expires_at"]) == expires_at


def test_latest_advisory_is_returned(client, db_session):
    user, headers = register_and_login(client, "9600000002")
    crop = create_crop(db_session, user["id"])
    older = create_advisory(
        db_session,
        crop,
        created_at=datetime(2026, 9, 1, tzinfo=timezone.utc),
        title="Older advisory",
    )
    newer = create_advisory(
        db_session,
        crop,
        created_at=datetime(2026, 10, 1, tzinfo=timezone.utc),
        title="Newer advisory",
    )

    response = client.get(
        f"/api/v1/crops/{crop.id}/advisory",
        headers=headers,
    )

    assert response.status_code == 200
    assert response.json()["advisory"]["id"] == str(newer.id)
    assert response.json()["advisory"]["id"] != str(older.id)


def test_crop_without_advisory_returns_null_advisory(client, db_session):
    user, headers = register_and_login(client, "9600000003")
    crop = create_crop(db_session, user["id"])

    response = client.get(
        f"/api/v1/crops/{crop.id}/advisory",
        headers=headers,
    )

    assert response.status_code == 200
    assert response.json() == {
        "crop_id": str(crop.id),
        "advisory": None,
    }


def test_farmer_cannot_retrieve_another_farmers_advisory(client, db_session):
    owner, _ = register_and_login(client, "9600000004")
    _, other_headers = register_and_login(client, "9600000005")
    crop = create_crop(db_session, owner["id"])
    create_advisory(
        db_session,
        crop,
        created_at=datetime(2026, 10, 1, tzinfo=timezone.utc),
    )

    response = client.get(
        f"/api/v1/crops/{crop.id}/advisory",
        headers=other_headers,
    )

    assert response.status_code == 404


def test_unauthenticated_advisory_request_is_rejected(client):
    response = client.get(f"/api/v1/crops/{uuid4()}/advisory")

    assert response.status_code == 401
