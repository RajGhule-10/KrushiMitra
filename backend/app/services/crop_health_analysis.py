from dataclasses import dataclass
from datetime import date, timedelta
from uuid import UUID

from sqlalchemy.orm import Session

from app.advisory import generate_advisory
from app.core.errors import NotFoundException
from app.models.advisory import Advisory as PersistedAdvisory
from app.models.observation import CropObservation, HealthMetric
from app.models.user import User
from app.remote_sensing.exceptions import RemoteSensingProviderError
from app.remote_sensing.gee.ndvi import GeeNdviProcessor
from app.remote_sensing.gee.processor import GeeImageProcessor
from app.remote_sensing.gee.provider import GeeRemoteSensingProvider
from app.remote_sensing.gee.statistics import GeeNdviStatisticsProcessor
from app.repositories.crop_health import CropHealthRepository
from app.repositories.farm_boundary import FarmBoundaryRepository
from app.repositories.farmer_profile import FarmerProfileRepository
from app.services.advisory_persistence import AdvisoryPersistenceService
from app.services.ndvi_persistence import NdviPersistenceService


DEFAULT_LOOKBACK_DAYS = 30
DEFAULT_MAX_CLOUD_PERCENTAGE = 20.0


@dataclass(frozen=True)
class CropHealthAnalysisResult:
    crop_id: UUID
    observation: CropObservation
    metric: HealthMetric
    advisory: PersistedAdvisory


class CropHealthAnalysisService:
    """Orchestrate satellite-based crop-health analysis and persistence."""

    def __init__(
        self,
        db: Session,
        *,
        provider: GeeRemoteSensingProvider | None = None,
        image_processor: GeeImageProcessor | None = None,
        ndvi_processor: GeeNdviProcessor | None = None,
        statistics_processor: GeeNdviStatisticsProcessor | None = None,
        ndvi_persistence: NdviPersistenceService | None = None,
        advisory_persistence: AdvisoryPersistenceService | None = None,
    ) -> None:
        self.crop_health_repository = CropHealthRepository(db)
        self.farmer_profile_repository = FarmerProfileRepository(db)
        self.farm_boundary_repository = FarmBoundaryRepository(db)
        self.provider = provider or GeeRemoteSensingProvider()
        self.image_processor = image_processor or GeeImageProcessor()
        self.ndvi_processor = ndvi_processor or GeeNdviProcessor()
        self.statistics_processor = (
            statistics_processor or GeeNdviStatisticsProcessor()
        )
        self.ndvi_persistence = (
            ndvi_persistence or NdviPersistenceService(db)
        )
        self.advisory_persistence = (
            advisory_persistence or AdvisoryPersistenceService(db)
        )

    def analyze_crop_health(
        self,
        current_user: User,
        crop_id: UUID,
        analysis_date: date | None = None,
    ) -> CropHealthAnalysisResult:
        profile = self.farmer_profile_repository.get_by_user_id(current_user.id)
        if profile is None:
            raise NotFoundException("Crop not found.")

        crop = self.crop_health_repository.get_crop_by_id_for_farmer(
            crop_id,
            profile.id,
        )
        if crop is None:
            raise NotFoundException("Crop not found.")

        boundary = self.farm_boundary_repository.get_by_farm_id(crop.farm_id)
        if boundary is None:
            raise NotFoundException("Farm boundary not found.")

        geometry = self.farm_boundary_repository.get_geometry_as_geojson(boundary)
        end_date = analysis_date or date.today()
        start_date = end_date - timedelta(days=DEFAULT_LOOKBACK_DAYS)
        images = self.provider.search_images(
            geometry,
            start_date,
            end_date,
            DEFAULT_MAX_CLOUD_PERCENTAGE,
        )
        if not images:
            raise RemoteSensingProviderError(
                "No suitable satellite image was found for this crop."
            )

        image = max(
            images,
            key=lambda candidate: (
                candidate.acquisition_date,
                candidate.image_id,
            ),
        )
        processed_image = self.image_processor.process_image(image, geometry)
        ndvi_result = self.ndvi_processor.calculate_ndvi(processed_image)
        mean_ndvi = self.statistics_processor.calculate_mean(ndvi_result)
        observation, metric = self.ndvi_persistence.persist_mean_ndvi(
            crop.id,
            image,
            mean_ndvi,
        )
        advisory = generate_advisory(metric.health_status)
        persisted_advisory = self.advisory_persistence.persist(
            advisory,
            farm_id=crop.farm_id,
            crop_id=crop.id,
            observation_id=observation.id,
        )

        return CropHealthAnalysisResult(
            crop_id=crop.id,
            observation=observation,
            metric=metric,
            advisory=persisted_advisory,
        )
