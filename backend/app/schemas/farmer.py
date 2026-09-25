from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class FarmerProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    full_name: str
    village: str | None
    district: str | None
    state: str | None
    preferred_language: Literal["mr", "hi", "en"]


class FarmerProfileUpdateRequest(BaseModel):
    full_name: str = Field(default=None, min_length=2, max_length=150)
    village: str | None = Field(default=None, max_length=150)
    district: str | None = Field(default=None, max_length=150)
    state: str | None = Field(default=None, max_length=150)
    preferred_language: Literal["mr", "hi", "en"] = None
