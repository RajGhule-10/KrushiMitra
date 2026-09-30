import json
import sys
from types import SimpleNamespace
from unittest.mock import Mock

import pytest

from app.remote_sensing.exceptions import (
    RemoteSensingAuthenticationError,
    RemoteSensingProviderError,
)
from app.remote_sensing.gee.client import initialize_earth_engine


def _credential_file(tmp_path):
    path = tmp_path / "gee-credentials.json"
    path.write_text(
        json.dumps({"client_email": "gee@example.iam.gserviceaccount.com"}),
        encoding="utf-8",
    )
    return path


def _fake_ee():
    return SimpleNamespace(
        ServiceAccountCredentials=Mock(return_value="credentials"),
        Initialize=Mock(),
    )


def test_importing_gee_module_does_not_initialize_earth_engine():
    fake_ee = _fake_ee()
    sys.modules["ee"] = fake_ee
    try:
        import app.remote_sensing.gee

        fake_ee.Initialize.assert_not_called()
    finally:
        sys.modules.pop("ee", None)


def test_initialization_passes_project_and_service_account_file(
    tmp_path,
    monkeypatch,
):
    fake_ee = _fake_ee()
    monkeypatch.setitem(sys.modules, "ee", fake_ee)
    credential_path = _credential_file(tmp_path)

    initialize_earth_engine("krushimitra-dev", str(credential_path))

    fake_ee.ServiceAccountCredentials.assert_called_once_with(
        "gee@example.iam.gserviceaccount.com",
        str(credential_path),
    )
    fake_ee.Initialize.assert_called_once_with(
        "credentials",
        project="krushimitra-dev",
    )


def test_missing_credentials_are_reported_as_authentication_error(tmp_path):
    with pytest.raises(
        RemoteSensingAuthenticationError,
        match="credential file was not found",
    ):
        initialize_earth_engine(
            "krushimitra-dev",
            str(tmp_path / "missing.json"),
        )


def test_missing_credential_configuration_is_reported():
    with pytest.raises(
        RemoteSensingAuthenticationError,
        match="credentials are not configured",
    ):
        initialize_earth_engine("krushimitra-dev")


def test_invalid_credential_file_is_reported_as_authentication_error(tmp_path):
    path = tmp_path / "invalid.json"
    path.write_text("not-json", encoding="utf-8")

    with pytest.raises(RemoteSensingAuthenticationError, match="invalid"):
        initialize_earth_engine("krushimitra-dev", str(path))


def test_credential_loading_failure_is_mapped_to_authentication_error(
    tmp_path,
    monkeypatch,
):
    fake_ee = _fake_ee()
    fake_ee.ServiceAccountCredentials.side_effect = RuntimeError("auth failed")
    monkeypatch.setitem(sys.modules, "ee", fake_ee)

    with pytest.raises(
        RemoteSensingAuthenticationError,
        match="credentials could not be loaded",
    ):
        initialize_earth_engine("krushimitra-dev", str(_credential_file(tmp_path)))


def test_initialization_failure_is_mapped_to_provider_error(tmp_path, monkeypatch):
    fake_ee = _fake_ee()
    fake_ee.Initialize.side_effect = RuntimeError("service unavailable")
    monkeypatch.setitem(sys.modules, "ee", fake_ee)

    with pytest.raises(
        RemoteSensingProviderError,
        match="could not be initialized",
    ):
        initialize_earth_engine("krushimitra-dev", str(_credential_file(tmp_path)))


def test_initialization_authentication_failure_is_mapped_to_auth_error(
    tmp_path,
    monkeypatch,
):
    fake_ee = _fake_ee()
    fake_ee.Initialize.side_effect = RuntimeError("authentication failed")
    monkeypatch.setitem(sys.modules, "ee", fake_ee)

    with pytest.raises(
        RemoteSensingAuthenticationError,
        match="authentication failed",
    ):
        initialize_earth_engine("krushimitra-dev", str(_credential_file(tmp_path)))


def test_project_id_is_required():
    with pytest.raises(RemoteSensingProviderError, match="project ID"):
        initialize_earth_engine("  ")
