from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator


class CropCreateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    crop_name: str = Field(min_length=2, max_length=150)
    variety: str | None = Field(default=None, max_length=150)
    sowing_date: date | None = None
    expected_harvest_date: date | None = None
    season: str = Field(min_length=1, max_length=50)
    status: str = Field(default="active", min_length=1, max_length=50)


class CropUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    crop_name: str | None = Field(default=None, min_length=2, max_length=150)
    variety: str | None = Field(default=None, max_length=150)
    sowing_date: date | None = None
    expected_harvest_date: date | None = None
    season: str | None = Field(default=None, min_length=1, max_length=50)
    status: str | None = Field(default=None, min_length=1, max_length=50)

    @model_validator(mode="after")
    def validate_required_fields_are_not_null(self) -> "CropUpdateRequest":
        for field in ("crop_name", "season", "status"):
            if field in self.model_fields_set and getattr(self, field) is None:
                raise ValueError(f"{field} cannot be null")
        return self


class CropResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    farm_id: UUID
    crop_name: str
    variety: str | None
    sowing_date: date | None
    expected_harvest_date: date | None
    season: str
    status: str
    created_at: datetime
    updated_at: datetime
