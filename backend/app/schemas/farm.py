from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator


class FarmCreateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str = Field(min_length=2, max_length=150)
    gat_number: str | None = Field(default=None, max_length=100)
    area_hectares: Decimal | None = Field(default=None, gt=0)
    village: str | None = Field(default=None, max_length=150)
    district: str | None = Field(default=None, max_length=150)
    state: str | None = Field(default=None, max_length=150)


class FarmUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str | None = Field(default=None, min_length=2, max_length=150)
    gat_number: str | None = Field(default=None, max_length=100)
    area_hectares: Decimal | None = Field(default=None, gt=0)
    village: str | None = Field(default=None, max_length=150)
    district: str | None = Field(default=None, max_length=150)
    state: str | None = Field(default=None, max_length=150)

    @model_validator(mode="after")
    def validate_name_is_not_null(self) -> "FarmUpdateRequest":
        if "name" in self.model_fields_set and self.name is None:
            raise ValueError("name cannot be null")
        return self


class FarmResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    gat_number: str | None
    area_hectares: Decimal | None
    village: str | None
    district: str | None
    state: str | None
    created_at: datetime
    updated_at: datetime
