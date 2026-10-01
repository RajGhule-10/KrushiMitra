from .models import Advisory, HealthStatus

ADVISORY_RULES: dict[HealthStatus, Advisory] = {
    "Great": Advisory(
        status="Great",
        priority="low",
        title="Crop health looks good",
        message=(
            "Current vegetation indicators show healthy crop growth. "
            "Continue regular field monitoring."
        ),
    ),
    "Good": Advisory(
        status="Good",
        priority="low",
        title="Crop is generally healthy",
        message=(
            "Current vegetation indicators are generally healthy. "
            "Continue regular monitoring of the field."
        ),
    ),
    "Bad": Advisory(
        status="Bad",
        priority="medium",
        title="Possible crop stress detected",
        message=(
            "Vegetation indicators show signs of stress. Inspect the field "
            "for possible causes such as water stress, pest pressure, disease "
            "symptoms, or other field conditions."
        ),
    ),
    "Severe": Advisory(
        status="Severe",
        priority="high",
        title="Significant crop stress detected",
        message=(
            "Vegetation indicators show significant stress. Inspect the "
            "affected field promptly and consider consulting a qualified "
            "agricultural expert to identify the cause."
        ),
    ),
}
