from datetime import date
from uuid import uuid4

import pytest
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from app.advisory import generate_advisory
from app.models.advisory import Advisory
from app.models.crop import Crop
from app.models.farm import Farm
from app.models.observation import CropObservation
from app.models.user import FarmerProfile, User
from app.services.advisory_persistence import AdvisoryPersistenceService


def _context(db_session):
    user = User(id=uuid4(), phone_number=f"96{uuid4().int % 10**8:08d}")
    profile = FarmerProfile(id=uuid4(), user_id=user.id, full_name="Advisory Farmer")
    farm = Farm(id=uuid4(), farmer_id=profile.id, name="Advisory Farm")
    crop = Crop(id=uuid4(), farm_id=farm.id, crop_name="Wheat", season="rabi")
    observation = CropObservation(
        id=uuid4(),
        crop_id=crop.id,
        observation_date=date(2026, 10, 1),
        data_source="sentinel-2",
    )
    db_session.add_all([user, profile, farm, crop, observation])
    db_session.commit()
    return farm, crop, observation


def test_advisory_persists_with_observation_reference(db_session):
    farm, crop, observation = _context(db_session)

    persisted = AdvisoryPersistenceService(db_session).persist(
        generate_advisory("Great"),
        farm.id,
        crop.id,
        observation.id,
    )

    row = db_session.scalar(select(Advisory).where(Advisory.id == persisted.id))
    assert row is not None
    assert row.observation_id == observation.id
    assert row.severity == "Great"
    assert row.priority == "low"


def test_invalid_observation_foreign_key_is_enforced(db_session):
    farm, crop, _ = _context(db_session)

    with pytest.raises(IntegrityError):
        AdvisoryPersistenceService(db_session).persist(
            generate_advisory("Bad"),
            farm.id,
            crop.id,
            uuid4(),
        )
        db_session.commit()
    db_session.rollback()


def test_persistence_error_rolls_back_advisory(db_session, monkeypatch):
    farm, crop, observation = _context(db_session)
    service = AdvisoryPersistenceService(db_session)

    def fail_commit():
        raise IntegrityError("forced", {}, None)

    monkeypatch.setattr(service.repository, "commit", fail_commit)
    with pytest.raises(IntegrityError):
        service.persist(
            generate_advisory("Severe"),
            farm.id,
            crop.id,
            observation.id,
        )

    assert db_session.scalar(select(Advisory).where(Advisory.farm_id == farm.id)) is None
