from datetime import date
from decimal import Decimal
from uuid import UUID, uuid4

import pytest

from app.core.errors import NotFoundException
from app.models.advisory import Advisory
from app.models.observation import CropObservation, HealthMetric
from app.services.crop_health_analysis import CropHealthAnalysisResult


def register_and_login(client, phone_number: str) -> tuple[dict, dict[str, str]]:
    registration = client.post(
        "/api/v1/auth/register",
        json={
            "phone_number": phone_number,
            "password": "TestPass123",
            "full_name": "Analysis API Farmer",
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


def analysis_result(crop_id: UUID) -> CropHealthAnalysisResult:
    observation = CropObservation(
        id=uuid4(),
        crop_id=crop_id,
        observation_date=date(2026, 10, 2),
        data_source="sentinel-2",
        cloud_percentage=Decimal("8.25"),
    )
    metric = HealthMetric(
        id=uuid4(),
        observation_id=observation.id,
        metric_name="ndvi_mean",
        metric_value=Decimal("0.420000"),
        health_status="Good",
    )
    advisory = Advisory(
        id=uuid4(),
        farm_id=uuid4(),
        crop_id=crop_id,
        observation_id=observation.id,
        title="Crop is generally healthy",
        message="Continue regular monitoring of the field.",
        severity="Good",
        priority="low",
        category="crop_health",
    )
    return CropHealthAnalysisResult(
        crop_id=crop_id,
        observation=observation,
        metric=metric,
        advisory=advisory,
    )


class FakeAnalysisService:
    result = None
    error = None
    calls = []

    def __init__(self, db):
        self.db = db

    def analyze_crop_health(self, current_user, crop_id):
        self.__class__.calls.append((current_user, crop_id))
        if self.error is not None:
            raise self.error
        return self.result


@pytest.fixture
def fake_analysis_service(monkeypatch):
    from app.api.routes import crop_health_analysis

    FakeAnalysisService.result = None
    FakeAnalysisService.error = None
    FakeAnalysisService.calls = []
    monkeypatch.setattr(
        crop_health_analysis,
        "CropHealthAnalysisService",
        FakeAnalysisService,
    )
    return FakeAnalysisService


def test_authenticated_analysis_returns_complete_response(
    client,
    fake_analysis_service,
):
    user, headers = register_and_login(client, "9700000001")
    crop_id = uuid4()
    result = analysis_result(crop_id)
    fake_analysis_service.result = result

    response = client.post(
        f"/api/v1/crops/{crop_id}/analyze",
        headers=headers,
    )

    assert response.status_code == 200
    assert response.json() == {
        "crop_id": str(crop_id),
        "observation": {
            "observation_date": "2026-10-02",
            "data_source": "sentinel-2",
            "cloud_percentage": "8.25",
        },
        "health": {
            "metric": "ndvi_mean",
            "value": "0.420000",
            "status": "Good",
        },
        "advisory": {
            "id": str(result.advisory.id),
            "title": "Crop is generally healthy",
            "message": "Continue regular monitoring of the field.",
            "severity": "Good",
            "priority": "low",
            "category": "crop_health",
        },
    }
    assert fake_analysis_service.calls[0][1] == crop_id
    assert fake_analysis_service.calls[0][0].id == UUID(user["id"])


def test_unauthenticated_analysis_request_is_rejected(client):
    response = client.post(f"/api/v1/crops/{uuid4()}/analyze")

    assert response.status_code == 401


def test_inaccessible_crop_returns_not_found(client, fake_analysis_service):
    _, headers = register_and_login(client, "9700000002")
    fake_analysis_service.error = NotFoundException("Crop not found.")

    response = client.post(
        f"/api/v1/crops/{uuid4()}/analyze",
        headers=headers,
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Crop not found."


def test_missing_farmer_profile_error_propagates(
    client,
    fake_analysis_service,
):
    _, headers = register_and_login(client, "9700000003")
    fake_analysis_service.error = NotFoundException("Crop not found.")

    response = client.post(
        f"/api/v1/crops/{uuid4()}/analyze",
        headers=headers,
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Crop not found."


def test_service_error_preserves_http_behavior(client, fake_analysis_service):
    _, headers = register_and_login(client, "9700000004")
    fake_analysis_service.error = NotFoundException(
        "Farm boundary not found."
    )

    response = client.post(
        f"/api/v1/crops/{uuid4()}/analyze",
        headers=headers,
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Farm boundary not found."


def test_decimal_values_are_serialized_without_float_conversion(
    client,
    fake_analysis_service,
):
    _, headers = register_and_login(client, "9700000005")
    crop_id = uuid4()
    fake_analysis_service.result = analysis_result(crop_id)

    response = client.post(
        f"/api/v1/crops/{crop_id}/analyze",
        headers=headers,
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["observation"]["cloud_percentage"] == "8.25"
    assert payload["health"]["value"] == "0.420000"
