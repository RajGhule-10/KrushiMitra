from uuid import uuid4

from app.models.user import User


def register_and_login(client, phone_number: str) -> tuple[dict, dict[str, str]]:
    register_response = client.post(
        "/api/v1/auth/register",
        json={
            "phone_number": phone_number,
            "password": "TestPass123",
            "full_name": "Raj Ghule",
            "village": "Loni",
            "district": "Pune",
            "state": "Maharashtra",
            "preferred_language": "mr",
        },
    )
    assert register_response.status_code == 201

    login_response = client.post(
        "/api/v1/auth/login",
        json={"phone_number": phone_number, "password": "TestPass123"},
    )
    assert login_response.status_code == 200

    return register_response.json(), {
        "Authorization": f"Bearer {login_response.json()['access_token']}",
    }


def test_authenticated_farmer_can_retrieve_own_profile(client):
    _, headers = register_and_login(client, "9100000001")

    response = client.get("/api/v1/farmer/profile", headers=headers)

    assert response.status_code == 200
    assert response.json()["full_name"] == "Raj Ghule"
    assert response.json()["id"]


def test_unauthenticated_farmer_profile_request_is_rejected(client):
    response = client.get("/api/v1/farmer/profile")

    assert response.status_code == 401


def test_authenticated_farmer_can_partially_update_profile(client):
    _, headers = register_and_login(client, "9100000002")

    response = client.patch(
        "/api/v1/farmer/profile",
        headers=headers,
        json={"district": "Satara"},
    )

    assert response.status_code == 200
    assert response.json()["full_name"] == "Raj Ghule"
    assert response.json()["village"] == "Loni"
    assert response.json()["district"] == "Satara"


def test_authenticated_farmer_can_update_full_name(client):
    _, headers = register_and_login(client, "9100000008")

    response = client.patch(
        "/api/v1/farmer/profile",
        headers=headers,
        json={"full_name": "Updated Farmer"},
    )

    assert response.status_code == 200
    assert response.json()["full_name"] == "Updated Farmer"


def test_invalid_preferred_language_is_rejected(client):
    _, headers = register_and_login(client, "9100000003")

    response = client.patch(
        "/api/v1/farmer/profile",
        headers=headers,
        json={"preferred_language": "fr"},
    )

    assert response.status_code == 422


def test_invalid_full_name_length_is_rejected(client):
    _, headers = register_and_login(client, "9100000004")

    response = client.patch(
        "/api/v1/farmer/profile",
        headers=headers,
        json={"full_name": "A"},
    )

    assert response.status_code == 422


def test_farmer_profile_is_scoped_to_authenticated_user(client):
    _, first_headers = register_and_login(client, "9100000005")
    _, second_headers = register_and_login(client, "9100000006")

    first_profile = client.get("/api/v1/farmer/profile", headers=first_headers)
    second_profile = client.get("/api/v1/farmer/profile", headers=second_headers)

    client.patch(
        "/api/v1/farmer/profile",
        headers=first_headers,
        json={"full_name": "First Farmer"},
    )
    response = client.get("/api/v1/farmer/profile", headers=second_headers)

    assert response.status_code == 200
    assert first_profile.json()["id"] != second_profile.json()["id"]
    assert response.json()["id"] == second_profile.json()["id"]
    assert response.json()["full_name"] == "Raj Ghule"


def test_missing_profile_returns_not_found(client, db_session):
    user = User(
        id=uuid4(),
        phone_number="9100000007",
        password_hash="unused",
        role="farmer",
        is_active=True,
    )
    db_session.add(user)
    db_session.commit()

    from app.auth.security import create_access_token

    headers = {
        "Authorization": (
            f"Bearer {create_access_token(subject=str(user.id), role=user.role)}"
        )
    }
    response = client.get("/api/v1/farmer/profile", headers=headers)

    assert response.status_code == 404
