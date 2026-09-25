from uuid import UUID

from pydantic import BaseModel, Field


class RegisterRequest(BaseModel):
    phone_number: str = Field(min_length=10, max_length=15)
    password: str = Field(min_length=8, max_length=128)
    full_name: str = Field(min_length=2, max_length=150)
    village: str | None = Field(default=None, max_length=150)
    district: str | None = Field(default=None, max_length=150)
    state: str | None = Field(default=None, max_length=150)
    preferred_language: str = Field(
        default="mr",
        min_length=2,
        max_length=5,
    )


class LoginRequest(BaseModel):
    phone_number: str = Field(min_length=10, max_length=15)
    password: str = Field(min_length=8, max_length=128)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class CurrentUserResponse(BaseModel):
    id: UUID
    phone_number: str
    role: str
    is_active: bool
