#!/usr/bin/env python3
"""
TechConnect — Script de seed des données de démonstration.

À exécuter UNIQUEMENT en environnement de développement :
    ENVIRONMENT=development python scripts/seed_demo.py

Ce script crée :
  - Un utilisateur client démo : client@techconnect.com / password123
  - Un technicien démo : tech@techconnect.com / password123
  - Deux bookings de démo complétés
  - Les catégories de services (idempotent)

NE JAMAIS exécuter en production.
"""
import asyncio
import os
import sys

# Guard: development only
ENVIRONMENT = os.getenv("ENVIRONMENT", "development")
if ENVIRONMENT != "development":
    print("❌ Ce script ne peut être exécuté qu'en environnement de développement.")
    print(f"   ENVIRONMENT={ENVIRONMENT}")
    sys.exit(1)

# Allow running from project root or backend/
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app.infrastructure.database.session import engine, Base, AsyncSessionLocal
from app.infrastructure.repositories.sqlalchemy_repositories import (
    SQLAlchemyCategoryRepository, SQLAlchemyUserRepository,
    SQLAlchemyTechnicianRepository, SQLAlchemyBookingRepository,
)
from app.domain.models import (
    UserDomain, UserRole, TechnicianProfileDomain, AvailabilityStatus,
    BookingDomain, BookingStatus,
)
from app.core.security import hash_password


async def seed():
    print("🌱 Création des tables...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as session:
        cat_repo = SQLAlchemyCategoryRepository(session)
        user_repo = SQLAlchemyUserRepository(session)
        tech_repo = SQLAlchemyTechnicianRepository(session)
        booking_repo = SQLAlchemyBookingRepository(session)

        # Categories
        print("📁 Seeding catégories...")
        await cat_repo.seed_defaults()

        # Demo Client
        if not await user_repo.get_by_email("client@techconnect.com"):
            print("👤 Création client démo...")
            client = UserDomain(
                id="user_client_demo",
                name="Mamadou Diop",
                phone="+221770000001",
                email="client@techconnect.com",
                role=UserRole.CLIENT,
                password_hash=hash_password("password123"),
            )
            await user_repo.create(client)
        else:
            print("   ↳ Client démo existe déjà.")

        # Demo Technician
        if not await user_repo.get_by_email("tech@techconnect.com"):
            print("🔧 Création technicien démo...")
            tech_user = UserDomain(
                id="user_tech_demo",
                name="Ousmane Sow",
                phone="+221770000002",
                email="tech@techconnect.com",
                role=UserRole.TECHNICIAN,
                password_hash=hash_password("password123"),
            )
            await user_repo.create(tech_user)

            tech_profile = TechnicianProfileDomain(
                id="tech_profile_demo",
                user_id="user_tech_demo",
                category_ids=["cat_plumbing", "cat_electrical", "cat_hvac"],
                latitude=14.6937,
                longitude=-17.4441,
                availability_status=AvailabilityStatus.ONLINE,
                average_rating=4.9,
                verified=True,
                user_name="Ousmane Sow",
                user_phone="+221770000002",
            )
            await tech_repo.create_profile(tech_profile)
        else:
            print("   ↳ Technicien démo existe déjà.")

        # Demo Bookings
        if not await booking_repo.get_by_id("bk_seed_1"):
            print("📋 Création booking démo 1...")
            await booking_repo.create(BookingDomain(
                id="bk_seed_1",
                client_id="user_client_demo",
                category_id="cat_plumbing",
                description="Remplacement colonne de douche & fuite d'eau encastrée sous évier",
                photo_url=None,
                status=BookingStatus.COMPLETED,
                latitude=14.6937,
                longitude=-17.4441,
                address_text="Sacré Cœur 3, Dakar",
                technician_id="user_tech_demo",
                scheduled_eta="Terminée",
            ))

        if not await booking_repo.get_by_id("bk_seed_2"):
            print("📋 Création booking démo 2...")
            await booking_repo.create(BookingDomain(
                id="bk_seed_2",
                client_id="user_client_demo",
                category_id="cat_hvac",
                description="Recharge fluide R410A & maintenance préventive climatiseur 12000 BTU",
                photo_url=None,
                status=BookingStatus.COMPLETED,
                latitude=14.7100,
                longitude=-17.4600,
                address_text="Mermoz Pyrotechnie, Dakar",
                technician_id="user_tech_demo",
                scheduled_eta="Terminée",
            ))

    print("\n✅ Seed terminé avec succès !")
    print("   Client  : client@techconnect.com / password123")
    print("   Technicien : tech@techconnect.com / password123")


if __name__ == "__main__":
    asyncio.run(seed())
