from uuid import uuid4

from tests.api.test_farm import create_farm, register_and_login


def create_crop(client, headers: dict[str, str], farm_id: str, **overrides):
    payload = {
        "crop_name": "Wheat",
        "variety": "Lokwan",
        "sowing_date": "2026-06-15",
        "expected_harvest_date": "2026-10-15",
        "season": "kharif",
    }
    payload.update(overrides)
    response = client.post(
        f"/api/v1/farms/{farm_id}/crops",
        headers=headers,
        json=payload,
    )
    assert response.status_code == 201
    return response.json()


def test_farmer_can_create_crop_for_owned_farm(client):
    headers = register_and_login(client, "9210000001")
    farm = create_farm(client, headers)

    crop = create_crop(client, headers, farm["id"])

    assert crop["farm_id"] == farm["id"]
    assert crop["crop_name"] == "Wheat"
    assert crop["variety"] == "Lokwan"
    assert crop["season"] == "kharif"
    assert crop["status"] == "active"


def test_farmer_can_list_owned_farm_crops(client):
    headers = register_and_login(client, "9210000002")
    farm = create_farm(client, headers)
    first = create_crop(client, headers, farm["id"], crop_name="Wheat")
    second = create_crop(client, headers, farm["id"], crop_name="Soybean")

    response = client.get(
        f"/api/v1/farms/{farm['id']}/crops",
        headers=headers,
    )

    assert response.status_code == 200
    assert {crop["id"] for crop in response.json()} == {first["id"], second["id"]}


def test_farmer_can_retrieve_owned_crop(client):
    headers = register_and_login(client, "9210000003")
    farm = create_farm(client, headers)
    crop = create_crop(client, headers, farm["id"])

    response = client.get(f"/api/v1/crops/{crop['id']}", headers=headers)

    assert response.status_code == 200
    assert response.json()["id"] == crop["id"]


def test_farmer_can_update_owned_crop(client):
    headers = register_and_login(client, "9210000004")
    farm = create_farm(client, headers)
    crop = create_crop(client, headers, farm["id"])

    response = client.patch(
        f"/api/v1/crops/{crop['id']}",
        headers=headers,
        json={"crop_name": "Updated Wheat", "status": "harvested"},
    )

    assert response.status_code == 200
    assert response.json()["crop_name"] == "Updated Wheat"
    assert response.json()["status"] == "harvested"
    assert response.json()["variety"] == "Lokwan"


def test_farmer_cannot_create_crop_for_another_farmers_farm(client):
    owner_headers = register_and_login(client, "9210000005")
    other_headers = register_and_login(client, "9210000006")
    farm = create_farm(client, owner_headers)

    response = client.post(
        f"/api/v1/farms/{farm['id']}/crops",
        headers=other_headers,
        json={"crop_name": "Wheat", "season": "kharif"},
    )

    assert response.status_code == 404


def test_farmer_cannot_list_another_farmers_crops(client):
    owner_headers = register_and_login(client, "9210000007")
    other_headers = register_and_login(client, "9210000008")
    farm = create_farm(client, owner_headers)
    create_crop(client, owner_headers, farm["id"])

    response = client.get(
        f"/api/v1/farms/{farm['id']}/crops",
        headers=other_headers,
    )

    assert response.status_code == 404


def test_farmer_cannot_retrieve_another_farmers_crop(client):
    owner_headers = register_and_login(client, "9210000009")
    other_headers = register_and_login(client, "9210000010")
    farm = create_farm(client, owner_headers)
    crop = create_crop(client, owner_headers, farm["id"])

    response = client.get(f"/api/v1/crops/{crop['id']}", headers=other_headers)

    assert response.status_code == 404


def test_farmer_cannot_update_another_farmers_crop(client):
    owner_headers = register_and_login(client, "9210000011")
    other_headers = register_and_login(client, "9210000012")
    farm = create_farm(client, owner_headers)
    crop = create_crop(client, owner_headers, farm["id"])

    response = client.patch(
        f"/api/v1/crops/{crop['id']}",
        headers=other_headers,
        json={"crop_name": "Attempted Takeover"},
    )

    assert response.status_code == 404


def test_missing_crop_returns_not_found(client):
    headers = register_and_login(client, "9210000013")

    response = client.get(f"/api/v1/crops/{uuid4()}", headers=headers)

    assert response.status_code == 404


def test_farmer_with_no_crops_receives_empty_list(client):
    headers = register_and_login(client, "9210000014")
    farm = create_farm(client, headers)

    response = client.get(
        f"/api/v1/farms/{farm['id']}/crops",
        headers=headers,
    )

    assert response.status_code == 200
    assert response.json() == []
