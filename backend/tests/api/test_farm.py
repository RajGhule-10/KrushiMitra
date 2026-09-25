from uuid import uuid4


def register_and_login(client, phone_number: str) -> dict[str, str]:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "phone_number": phone_number,
            "password": "TestPass123",
            "full_name": "Farm Test Farmer",
        },
    )
    assert response.status_code == 201

    response = client.post(
        "/api/v1/auth/login",
        json={"phone_number": phone_number, "password": "TestPass123"},
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def create_farm(client, headers: dict[str, str], **overrides: object) -> dict:
    payload = {
        "name": "Wheat Farm",
        "gat_number": "123",
        "area_hectares": "2.45",
        "village": "Loni",
        "district": "Pune",
        "state": "Maharashtra",
    }
    payload.update(overrides)
    response = client.post("/api/v1/farms", headers=headers, json=payload)
    assert response.status_code == 201
    return response.json()


def test_authenticated_farmer_can_create_a_farm(client):
    headers = register_and_login(client, "9200000001")

    farm = create_farm(client, headers)

    assert farm["name"] == "Wheat Farm"
    assert farm["gat_number"] == "123"
    assert farm["area_hectares"] == "2.4500"
    assert farm["district"] == "Pune"


def test_create_farm_rejects_client_supplied_farmer_id(client):
    headers = register_and_login(client, "9200000002")

    response = client.post(
        "/api/v1/farms",
        headers=headers,
        json={"name": "Owned Farm", "farmer_id": str(uuid4())},
    )

    assert response.status_code == 422


def test_authenticated_farmer_can_list_farms(client):
    headers = register_and_login(client, "9200000003")
    created_farm = create_farm(client, headers)

    response = client.get("/api/v1/farms", headers=headers)

    assert response.status_code == 200
    assert [farm["id"] for farm in response.json()] == [created_farm["id"]]


def test_farmer_with_no_farms_receives_empty_list(client):
    headers = register_and_login(client, "9200000004")

    response = client.get("/api/v1/farms", headers=headers)

    assert response.status_code == 200
    assert response.json() == []


def test_authenticated_farmer_can_retrieve_own_farm(client):
    headers = register_and_login(client, "9200000005")
    created_farm = create_farm(client, headers)

    response = client.get(f"/api/v1/farms/{created_farm['id']}", headers=headers)

    assert response.status_code == 200
    assert response.json()["id"] == created_farm["id"]
    assert response.json()["name"] == "Wheat Farm"


def test_farmer_cannot_retrieve_another_farmers_farm(client):
    owner_headers = register_and_login(client, "9200000006")
    other_headers = register_and_login(client, "9200000007")
    created_farm = create_farm(client, owner_headers)

    response = client.get(
        f"/api/v1/farms/{created_farm['id']}", headers=other_headers
    )

    assert response.status_code == 404


def test_authenticated_farmer_can_update_own_farm(client):
    headers = register_and_login(client, "9200000008")
    created_farm = create_farm(client, headers)

    response = client.patch(
        f"/api/v1/farms/{created_farm['id']}",
        headers=headers,
        json={"name": "Updated Wheat Farm", "area_hectares": "3.25"},
    )

    assert response.status_code == 200
    assert response.json()["name"] == "Updated Wheat Farm"
    assert response.json()["area_hectares"] == "3.2500"


def test_farmer_cannot_update_another_farmers_farm(client):
    owner_headers = register_and_login(client, "9200000009")
    other_headers = register_and_login(client, "9200000010")
    created_farm = create_farm(client, owner_headers)

    response = client.patch(
        f"/api/v1/farms/{created_farm['id']}",
        headers=other_headers,
        json={"name": "Attempted Takeover"},
    )

    assert response.status_code == 404


def test_farm_patch_preserves_omitted_fields(client):
    headers = register_and_login(client, "9200000011")
    created_farm = create_farm(client, headers)

    response = client.patch(
        f"/api/v1/farms/{created_farm['id']}",
        headers=headers,
        json={"district": "Satara"},
    )

    assert response.status_code == 200
    assert response.json()["name"] == "Wheat Farm"
    assert response.json()["gat_number"] == "123"
    assert response.json()["area_hectares"] == "2.4500"
    assert response.json()["village"] == "Loni"
    assert response.json()["district"] == "Satara"
    assert response.json()["state"] == "Maharashtra"


def test_invalid_farm_name_is_rejected(client):
    headers = register_and_login(client, "9200000012")

    response = client.post("/api/v1/farms", headers=headers, json={"name": "A"})

    assert response.status_code == 422


def test_non_positive_area_is_rejected(client):
    headers = register_and_login(client, "9200000013")

    response = client.post(
        "/api/v1/farms",
        headers=headers,
        json={"name": "Invalid Area Farm", "area_hectares": "0"},
    )

    assert response.status_code == 422


def test_invalid_field_length_is_rejected(client):
    headers = register_and_login(client, "9200000014")

    response = client.post(
        "/api/v1/farms",
        headers=headers,
        json={"name": "Length Farm", "gat_number": "1" * 101},
    )

    assert response.status_code == 422


def test_unauthenticated_farm_creation_is_rejected(client):
    response = client.post("/api/v1/farms", json={"name": "Unauthenticated Farm"})

    assert response.status_code == 401


def test_unauthenticated_farm_listing_is_rejected(client):
    response = client.get("/api/v1/farms")

    assert response.status_code == 401


def test_unauthenticated_farm_retrieval_is_rejected(client):
    response = client.get(f"/api/v1/farms/{uuid4()}")

    assert response.status_code == 401


def test_unauthenticated_farm_update_is_rejected(client):
    response = client.patch(
        f"/api/v1/farms/{uuid4()}",
        json={"name": "Unauthenticated Farm"},
    )

    assert response.status_code == 401


def test_farmer_can_manage_multiple_farms(client):
    headers = register_and_login(client, "9200000015")
    first_farm = create_farm(client, headers, name="First Farm")
    second_farm = create_farm(client, headers, name="Second Farm")

    response = client.get("/api/v1/farms", headers=headers)

    assert response.status_code == 200
    assert {farm["id"] for farm in response.json()} == {
        first_farm["id"],
        second_farm["id"],
    }
    assert {farm["name"] for farm in response.json()} == {"First Farm", "Second Farm"}


def test_listing_farms_does_not_expose_other_farmers_farms(client):
    first_headers = register_and_login(client, "9200000016")
    second_headers = register_and_login(client, "9200000017")
    first_farm = create_farm(client, first_headers, name="First Farmer Farm")
    second_farm = create_farm(client, second_headers, name="Second Farmer Farm")

    response = client.get("/api/v1/farms", headers=first_headers)

    assert response.status_code == 200
    assert [farm["id"] for farm in response.json()] == [first_farm["id"]]
    assert second_farm["id"] not in {farm["id"] for farm in response.json()}
