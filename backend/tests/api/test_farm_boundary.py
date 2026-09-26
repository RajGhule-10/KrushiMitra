from uuid import uuid4


POLYGON = {
    "type": "Polygon",
    "coordinates": [
        [
            [73.8567, 18.5204],
            [73.8575, 18.5204],
            [73.8575, 18.5212],
            [73.8567, 18.5212],
            [73.8567, 18.5204],
        ]
    ],
}

MULTI_POLYGON = {
    "type": "MultiPolygon",
    "coordinates": [
        POLYGON["coordinates"],
        [
            [
                [73.8580, 18.5204],
                [73.8588, 18.5204],
                [73.8588, 18.5212],
                [73.8580, 18.5212],
                [73.8580, 18.5204],
            ]
        ],
    ],
}


def register_and_login(client, phone_number: str) -> dict[str, str]:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "phone_number": phone_number,
            "password": "TestPass123",
            "full_name": "Boundary Test Farmer",
        },
    )
    assert response.status_code == 201

    response = client.post(
        "/api/v1/auth/login",
        json={"phone_number": phone_number, "password": "TestPass123"},
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def create_farm(client, headers: dict[str, str], name: str = "Boundary Farm") -> dict:
    response = client.post("/api/v1/farms", headers=headers, json={"name": name})
    assert response.status_code == 201
    return response.json()


def put_boundary(client, headers: dict[str, str], farm_id: str, geometry: dict) -> dict:
    response = client.put(
        f"/api/v1/farms/{farm_id}/boundary",
        headers=headers,
        json=geometry,
    )
    assert response.status_code == 200
    return response.json()


def test_authenticated_farmer_can_create_polygon_boundary(client):
    headers = register_and_login(client, "9300000001")
    farm = create_farm(client, headers)

    boundary = put_boundary(client, headers, farm["id"], POLYGON)

    assert boundary["farm_id"] == farm["id"]
    assert boundary["geometry"]["type"] == "MultiPolygon"


def test_polygon_boundary_is_normalized_to_multi_polygon(client):
    headers = register_and_login(client, "9300000002")
    farm = create_farm(client, headers)

    boundary = put_boundary(client, headers, farm["id"], POLYGON)

    assert boundary["geometry"]["coordinates"] == [POLYGON["coordinates"]]


def test_authenticated_farmer_can_get_own_boundary(client):
    headers = register_and_login(client, "9300000003")
    farm = create_farm(client, headers)
    put_boundary(client, headers, farm["id"], POLYGON)

    response = client.get(f"/api/v1/farms/{farm['id']}/boundary", headers=headers)

    assert response.status_code == 200
    assert response.json()["farm_id"] == farm["id"]
    assert response.json()["geometry"]["type"] == "MultiPolygon"
    assert response.json()["geometry"]["coordinates"] == [POLYGON["coordinates"]]


def test_authenticated_farmer_can_replace_existing_boundary(client):
    headers = register_and_login(client, "9300000004")
    farm = create_farm(client, headers)
    put_boundary(client, headers, farm["id"], POLYGON)

    boundary = put_boundary(client, headers, farm["id"], MULTI_POLYGON)
    response = client.get(f"/api/v1/farms/{farm['id']}/boundary", headers=headers)

    assert boundary["geometry"]["coordinates"] == MULTI_POLYGON["coordinates"]
    assert response.json()["geometry"]["coordinates"] == MULTI_POLYGON["coordinates"]


def test_authenticated_farmer_can_create_multi_polygon_boundary(client):
    headers = register_and_login(client, "9300000005")
    farm = create_farm(client, headers)

    boundary = put_boundary(client, headers, farm["id"], MULTI_POLYGON)

    assert boundary["geometry"]["type"] == "MultiPolygon"
    assert boundary["geometry"]["coordinates"] == MULTI_POLYGON["coordinates"]


def test_unauthenticated_boundary_put_is_rejected(client):
    response = client.put(f"/api/v1/farms/{uuid4()}/boundary", json=POLYGON)

    assert response.status_code == 401


def test_unauthenticated_boundary_get_is_rejected(client):
    response = client.get(f"/api/v1/farms/{uuid4()}/boundary")

    assert response.status_code == 401


def test_farmer_cannot_get_another_farmers_boundary(client):
    owner_headers = register_and_login(client, "9300000006")
    other_headers = register_and_login(client, "9300000007")
    farm = create_farm(client, owner_headers)
    put_boundary(client, owner_headers, farm["id"], POLYGON)

    response = client.get(
        f"/api/v1/farms/{farm['id']}/boundary", headers=other_headers
    )

    assert response.status_code == 404


def test_farmer_cannot_put_boundary_on_another_farmers_farm(client):
    owner_headers = register_and_login(client, "9300000008")
    other_headers = register_and_login(client, "9300000009")
    farm = create_farm(client, owner_headers)

    response = client.put(
        f"/api/v1/farms/{farm['id']}/boundary",
        headers=other_headers,
        json=POLYGON,
    )

    assert response.status_code == 404


def test_boundary_for_nonexistent_farm_returns_not_found(client):
    headers = register_and_login(client, "9300000010")

    response = client.put(
        f"/api/v1/farms/{uuid4()}/boundary", headers=headers, json=POLYGON
    )

    assert response.status_code == 404


def test_farm_without_boundary_returns_not_found(client):
    headers = register_and_login(client, "9300000011")
    farm = create_farm(client, headers)

    response = client.get(f"/api/v1/farms/{farm['id']}/boundary", headers=headers)

    assert response.status_code == 404


def test_invalid_geometry_is_rejected(client):
    headers = register_and_login(client, "9300000012")
    farm = create_farm(client, headers)
    invalid_polygon = {
        "type": "Polygon",
        "coordinates": [
            [[73.0, 18.0], [74.0, 19.0], [74.0, 18.0], [73.0, 19.0], [73.0, 18.0]]
        ],
    }

    response = client.put(
        f"/api/v1/farms/{farm['id']}/boundary",
        headers=headers,
        json=invalid_polygon,
    )

    assert response.status_code == 422


def test_unsupported_geometry_type_is_rejected(client):
    headers = register_and_login(client, "9300000013")
    farm = create_farm(client, headers)

    response = client.put(
        f"/api/v1/farms/{farm['id']}/boundary",
        headers=headers,
        json={"type": "LineString", "coordinates": [[73.0, 18.0], [74.0, 19.0]]},
    )

    assert response.status_code == 422


def test_empty_geometry_is_rejected(client):
    headers = register_and_login(client, "9300000014")
    farm = create_farm(client, headers)

    response = client.put(
        f"/api/v1/farms/{farm['id']}/boundary",
        headers=headers,
        json={"type": "Polygon", "coordinates": []},
    )

    assert response.status_code == 422


def test_invalid_coordinate_range_is_rejected(client):
    headers = register_and_login(client, "9300000015")
    farm = create_farm(client, headers)
    invalid_range_polygon = {
        "type": "Polygon",
        "coordinates": [
            [[181.0, 18.0], [74.0, 18.0], [74.0, 19.0], [181.0, 18.0]]
        ],
    }

    response = client.put(
        f"/api/v1/farms/{farm['id']}/boundary",
        headers=headers,
        json=invalid_range_polygon,
    )

    assert response.status_code == 422


def test_malformed_geojson_is_rejected(client):
    headers = register_and_login(client, "9300000016")
    farm = create_farm(client, headers)

    response = client.put(
        f"/api/v1/farms/{farm['id']}/boundary",
        headers=headers,
        json={"type": "Polygon", "coordinates": "not coordinates"},
    )

    assert response.status_code == 422
