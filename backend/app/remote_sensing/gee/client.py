import importlib
import json
from pathlib import Path

from app.remote_sensing.exceptions import (
    RemoteSensingAuthenticationError,
    RemoteSensingProviderError,
)


def initialize_earth_engine(
    project_id: str,
    credentials_path: str | None = None,
) -> None:
    """Initialize Earth Engine explicitly for the configured project.

    The credential file must be a service-account JSON file containing a
    ``client_email`` field. Credential contents are never included in errors.
    """
    if not project_id.strip():
        raise RemoteSensingProviderError(
            "A Google Earth Engine project ID is required."
        )

    if not credentials_path:
        raise RemoteSensingAuthenticationError(
            "Google Earth Engine credentials are not configured."
        )

    credential_file = Path(credentials_path).expanduser()
    if not credential_file.is_file():
        raise RemoteSensingAuthenticationError(
            "Google Earth Engine credential file was not found."
        )

    try:
        credential_data = json.loads(credential_file.read_text(encoding="utf-8"))
        service_account_email = credential_data["client_email"]
        if not isinstance(service_account_email, str) or not service_account_email:
            raise ValueError("Missing client_email.")
    except (OSError, json.JSONDecodeError, KeyError, TypeError, ValueError) as error:
        raise RemoteSensingAuthenticationError(
            "Google Earth Engine credential file is invalid."
        ) from error

    try:
        ee = importlib.import_module("ee")
    except ImportError as error:
        raise RemoteSensingProviderError(
            "The Google Earth Engine SDK is not installed."
        ) from error

    try:
        credentials = ee.ServiceAccountCredentials(
            service_account_email,
            str(credential_file),
        )
    except Exception as error:
        raise RemoteSensingAuthenticationError(
            "Google Earth Engine credentials could not be loaded."
        ) from error

    try:
        ee.Initialize(credentials, project=project_id)
    except RemoteSensingAuthenticationError:
        raise
    except Exception as error:
        if _looks_like_authentication_error(error):
            raise RemoteSensingAuthenticationError(
                "Google Earth Engine authentication failed."
            ) from error
        raise RemoteSensingProviderError(
            "Google Earth Engine could not be initialized."
        ) from error


def _looks_like_authentication_error(error: Exception) -> bool:
    """Classify SDK authentication failures without exposing their details."""
    error_name = type(error).__name__.lower()
    error_message = str(error).lower()
    authentication_terms = (
        "auth",
        "credential",
        "permission",
        "unauthorized",
        "forbidden",
    )
    return any(
        term in error_name or term in error_message
        for term in authentication_terms
    )
