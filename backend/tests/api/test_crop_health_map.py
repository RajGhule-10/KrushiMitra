from datetime import date
from uuid import uuid4

from app.remote_sensing.gee.visualization import GeeNdviVisualization
from app.services.crop_health_map import CropHealthMapResult


def register_and_login(client, phone_number):
    registration = client.post(
        "/api/v1/auth/register",
        json={
            "phone_number": phone_number,
            "password": "TestPass123",
            "full_name": "Map API Farmer",
        },
    )
    assert registration.status_code == 201
    login = client.post(
        "/api/v1/auth/login",
        json={"phone_number": phone_number, "password": "TestPass123"},
    )
    assert login.status_code == 200
    return {"Authorization": f"Bearer {login.json()['access_token']}"}


def unique_phone_number():
    return str(9000000000 + uuid4().int % 999999999)


class FakeTileFetcher:
    def fetch_tile(self, x, y, z):
        return b"png-bytes"


class FakeMapService:
    result = None
    calls = []

    def __init__(self, db):
        self.db = db

    def get_crop_health_map(self, current_user, crop_id):
        self.__class__.calls.append((current_user, crop_id))
        return self.result

    def get_tile(self, current_user, crop_id, z, x, y):
        self.__class__.calls.append((current_user, crop_id, z, x, y))
        return b"png-bytes"


def map_result(crop_id):
    return CropHealthMapResult(
        crop_id=crop_id,
        observation_date=date(2026, 10, 1),
        data_source="sentinel-2",
        visualization=GeeNdviVisualization(
            map_id="map",
            tile_fetcher=FakeTileFetcher(),
            minimum=-1.0,
            maximum=1.0,
            palette=("#8B0000", "#1B7837"),
        ),
    )


def test_authenticated_map_returns_contract(client, monkeypatch):
    from app.api.routes import crop_health_map

    monkeypatch.setattr(crop_health_map, "CropHealthMapService", FakeMapService)
    FakeMapService.calls = []
    crop_id = uuid4()
    FakeMapService.result = map_result(crop_id)
    headers = register_and_login(client, unique_phone_number())

    response = client.get(
        f"/api/v1/crops/{crop_id}/health/map",
        headers=headers,
    )

    assert response.status_code == 200
    assert response.json() == {
        "crop_id": str(crop_id),
        "observation_date": "2026-10-01",
        "data_source": "sentinel-2",
        "visualization": {
            "type": "ndvi",
            "min": -1.0,
            "max": 1.0,
            "palette": ["#8B0000", "#1B7837"],
        },
        "tile_url_template": (
            f"/api/v1/crops/{crop_id}/health/map/tiles/{{z}}/{{x}}/{{y}}"
        ),
    }


def test_unauthenticated_map_request_is_rejected(client):
    response = client.get(f"/api/v1/crops/{uuid4()}/health/map")

    assert response.status_code == 401


def test_authenticated_tile_returns_png(client, monkeypatch):
    from app.api.routes import crop_health_map

    monkeypatch.setattr(crop_health_map, "CropHealthMapService", FakeMapService)
    FakeMapService.calls = []
    headers = register_and_login(client, unique_phone_number())

    response = client.get(
        f"/api/v1/crops/{uuid4()}/health/map/tiles/3/2/1",
        headers=headers,
    )

    assert response.status_code == 200
    assert response.headers["content-type"] == "image/png"
    assert response.content == b"png-bytes"


def test_invalid_tile_coordinates_are_rejected(client, monkeypatch):
    from app.api.routes import crop_health_map

    monkeypatch.setattr(crop_health_map, "CropHealthMapService", FakeMapService)
    headers = register_and_login(client, unique_phone_number())

    response = client.get(
        f"/api/v1/crops/{uuid4()}/health/map/tiles/3/8/1",
        headers=headers,
    )

    assert response.status_code == 400
