import pytest

from app.auth.security import (
    create_access_token,
    decode_access_token,
    hash_password,
    verify_password,
)

from app.auth.security import (
    create_access_token,
    decode_access_token,
    hash_password,
    verify_password,
)


def test_password_hash_is_not_plain_text():
    password = "TestPass123"

    hashed_password = hash_password(password)

    assert hashed_password != password


def test_password_verification_succeeds_for_correct_password():
    password = "TestPass123"

    hashed_password = hash_password(password)

    assert verify_password(password, hashed_password) is True


def test_password_verification_fails_for_wrong_password():
    password = "TestPass123"

    hashed_password = hash_password(password)

    assert verify_password("WrongPassword", hashed_password) is False


def test_access_token_contains_expected_claims():
    user_id = "3cd11029-3297-4688-b206-a753960ef8a5"
    role = "farmer"

    token = create_access_token(
        subject=user_id,
        role=role,
    )

    payload = decode_access_token(token)

    assert payload["sub"] == user_id
    assert payload["role"] == role
    assert "exp" in payload

def test_access_token_can_be_decoded():
    token = create_access_token(
        subject="test-user-id",
        role="farmer",
    )

    payload = decode_access_token(token)

    assert payload["sub"] == "test-user-id"
    assert payload["role"] == "farmer"

def test_invalid_access_token_is_rejected():
    invalid_token = "this.is.not.a.valid.jwt"

    with pytest.raises(Exception):
        decode_access_token(invalid_token)    