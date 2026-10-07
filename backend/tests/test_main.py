from unittest.mock import Mock

import pytest
from fastapi.testclient import TestClient

from app import main
from app.remote_sensing.exceptions import (
    RemoteSensingAuthenticationError,
    RemoteSensingProviderError,
)


def _run_startup(monkeypatch, project_id, credentials_path):
    monkeypatch.setattr(main.settings, "gee_project_id", project_id)
    monkeypatch.setattr(main.settings, "gee_credentials_path", credentials_path)
    initializer = Mock()
    monkeypatch.setattr(main, "initialize_earth_engine", initializer)

    with TestClient(main.app):
        pass

    return initializer


def test_configured_gee_is_initialized_once(monkeypatch):
    initializer = _run_startup(
        monkeypatch,
        "riparian-eye",
        "/tmp/krushimitra-ee.json",
    )

    initializer.assert_called_once_with(
        project_id="riparian-eye",
        credentials_path="/tmp/krushimitra-ee.json",
    )


def test_missing_gee_configuration_allows_startup(monkeypatch):
    initializer = _run_startup(monkeypatch, None, None)

    initializer.assert_not_called()


def test_initialization_failure_propagates(monkeypatch):
    monkeypatch.setattr(main.settings, "gee_project_id", "riparian-eye")
    monkeypatch.setattr(
        main.settings,
        "gee_credentials_path",
        "/tmp/krushimitra-ee.json",
    )
    error = RemoteSensingAuthenticationError(
        "Google Earth Engine authentication failed."
    )
    initializer = Mock(side_effect=error)
    monkeypatch.setattr(main, "initialize_earth_engine", initializer)

    with pytest.raises(RemoteSensingAuthenticationError) as raised:
        with TestClient(main.app):
            pass

    assert raised.value is error
    initializer.assert_called_once_with(
        project_id="riparian-eye",
        credentials_path="/tmp/krushimitra-ee.json",
    )


@pytest.mark.parametrize(
    ("project_id", "credentials_path"),
    [
        ("riparian-eye", None),
        (None, "/tmp/krushimitra-ee.json"),
    ],
)
def test_partial_gee_configuration_fails_startup(
    monkeypatch,
    project_id,
    credentials_path,
):
    monkeypatch.setattr(main.settings, "gee_project_id", project_id)
    monkeypatch.setattr(main.settings, "gee_credentials_path", credentials_path)
    initializer = Mock()
    monkeypatch.setattr(main, "initialize_earth_engine", initializer)

    with pytest.raises(
        RemoteSensingProviderError,
        match="project ID and credentials path must be configured together",
    ):
        with TestClient(main.app):
            pass

    initializer.assert_not_called()
