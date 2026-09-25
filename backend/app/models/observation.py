import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Date, DateTime, ForeignKey, Numeric, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base


class CropObservation(Base):
    __tablename__ = "crop_observations"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    crop_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("crops.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    observation_date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
        index=True,
    )

    data_source: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    cloud_percentage: Mapped[Decimal | None] = mapped_column(
        Numeric(5, 2),
        nullable=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    crop: Mapped["Crop"] = relationship(
        back_populates="observations",
    )

    health_metrics: Mapped[list["HealthMetric"]] = relationship(
        back_populates="observation",
        cascade="all, delete-orphan",
    )


class HealthMetric(Base):
    __tablename__ = "health_metrics"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    observation_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("crop_observations.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    metric_name: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
    )

    metric_value: Mapped[Decimal] = mapped_column(
        Numeric(10, 6),
        nullable=False,
    )

    health_status: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    observation: Mapped["CropObservation"] = relationship(
        back_populates="health_metrics",
    )
