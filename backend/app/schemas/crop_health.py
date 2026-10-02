from datetime import date
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel


class LatestCropHealthObservation(BaseModel):
    observation_date: date
    data_source: str
    cloud_percentage: Decimal | None
    ndvi_mean: Decimal


class CropHealthResponse(BaseModel):
    crop_id: UUID
    crop_name: str
    latest_observation: LatestCropHealthObservation | None = None


class CropHealthAnalysisObservationResponse(BaseModel):
    observation_date: date
    data_source: str
    cloud_percentage: Decimal | None


class CropHealthAnalysisHealthResponse(BaseModel):
    metric: str
    value: Decimal
    status: str


class CropHealthAnalysisAdvisoryResponse(BaseModel):
    id: UUID
    title: str
    message: str
    severity: str
    priority: str
    category: str


class CropHealthAnalysisResponse(BaseModel):
    crop_id: UUID
    observation: CropHealthAnalysisObservationResponse
    health: CropHealthAnalysisHealthResponse
    advisory: CropHealthAnalysisAdvisoryResponse
