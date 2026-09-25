def test_register_user(client):
    response = client.post(
        "/api/v1/auth/register",
        json={
            "phone_number": "9000000001",
            "password": "TestPass123",
            "full_name": "Test Farmer",
            "village": "Test Village",
            "district": "Pune",
            "state": "Maharashtra",
            "preferred_language": "mr",
        },
    )

    assert response.status_code == 201

    data = response.json()

    assert data["phone_number"] == "9000000001"
    assert data["role"] == "farmer"
    assert data["is_active"] is True
    assert "id" in data

def test_login_user(client):
    register_response = client.post(
        "/api/v1/auth/register",
        json={
            "phone_number": "9000000002",
            "password": "TestPass123",
            "full_name": "Login Test Farmer",
        },
    )

    assert register_response.status_code == 201

    response = client.post(
        "/api/v1/auth/login",
        json={
            "phone_number": "9000000002",
            "password": "TestPass123",
        },
    )

    assert response.status_code == 200

    data = response.json()

    assert "access_token" in data
    assert data["token_type"] == "bearer"

def test_get_current_user(client):
    client.post(
        "/api/v1/auth/register",
        json={
            "phone_number": "9000000003",
            "password": "TestPass123",
            "full_name": "Current User Test",
        },
    )

    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "phone_number": "9000000003",
            "password": "TestPass123",
        },
    )

    token = login_response.json()["access_token"]

    response = client.get(
        "/api/v1/auth/me",
        headers={
            "Authorization": f"Bearer {token}",
        },
    )

    assert response.status_code == 200

    data = response.json()

    assert data["phone_number"] == "9000000003"
    assert data["role"] == "farmer"
    assert data["is_active"] is True

def test_duplicate_phone_number_is_rejected(client):
    payload = {
        "phone_number": "9000000004",
        "password": "TestPass123",
        "full_name": "Duplicate Test",
    }

    first_response = client.post(
        "/api/v1/auth/register",
        json=payload,
    )

    assert first_response.status_code == 201

    second_response = client.post(
        "/api/v1/auth/register",
        json=payload,
    )

    assert second_response.status_code == 400

def test_login_with_wrong_password_is_rejected(client):
    client.post(
        "/api/v1/auth/register",
        json={
            "phone_number": "9000000005",
            "password": "CorrectPass123",
            "full_name": "Wrong Password Test",
        },
    )

    response = client.post(
        "/api/v1/auth/login",
        json={
            "phone_number": "9000000005",
            "password": "WrongPass123",
        },
    )

    assert response.status_code == 401

def test_get_current_user_without_token_is_rejected(client):
    response = client.get("/api/v1/auth/me")

    assert response.status_code == 401