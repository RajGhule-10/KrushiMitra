import pytest

from app.advisory import generate_advisory


@pytest.mark.parametrize(
    (
        "health_status",
        "priority",
        "title",
        "message",
    ),
    [
        (
            "Great",
            "low",
            "Crop health looks good",
            "Current vegetation indicators show healthy crop growth. "
            "Continue regular field monitoring.",
        ),
        (
            "Good",
            "low",
            "Crop is generally healthy",
            "Current vegetation indicators are generally healthy. "
            "Continue regular monitoring of the field.",
        ),
        (
            "Bad",
            "medium",
            "Possible crop stress detected",
            "Vegetation indicators show signs of stress. Inspect the field "
            "for possible causes such as water stress, pest pressure, disease "
            "symptoms, or other field conditions.",
        ),
        (
            "Severe",
            "high",
            "Significant crop stress detected",
            "Vegetation indicators show significant stress. Inspect the "
            "affected field promptly and consider consulting a qualified "
            "agricultural expert to identify the cause.",
        ),
    ],
)
def test_generate_advisory_returns_expected_rule(
    health_status,
    priority,
    title,
    message,
):
    advisory = generate_advisory(health_status)

    assert advisory.status == health_status
    assert advisory.priority == priority
    assert advisory.title == title
    assert advisory.message == message


def test_generate_advisory_rejects_unsupported_status():
    with pytest.raises(ValueError, match="Unsupported crop health status"):
        generate_advisory("Unknown")
