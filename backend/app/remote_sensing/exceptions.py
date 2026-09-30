class RemoteSensingError(Exception):
    """Base exception for remote-sensing domain and provider failures."""


class RemoteSensingProviderError(RemoteSensingError):
    """A provider returned an error while handling a request."""


class RemoteSensingAuthenticationError(RemoteSensingProviderError):
    """Provider authentication failed."""


class RemoteSensingUnavailableError(RemoteSensingProviderError):
    """A provider is temporarily unavailable."""
