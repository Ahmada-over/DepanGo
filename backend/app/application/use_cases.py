import uuid
import asyncio
import logging
from datetime import datetime
from typing import Optional, List
from app.application.ports import (
    UserRepositoryPort, TechnicianRepositoryPort, CategoryRepositoryPort,
    BookingRepositoryPort, MessageRepositoryPort, ReviewRepositoryPort, PaymentRepositoryPort
)
from app.domain.models import (
    UserDomain, UserRole, TechnicianProfileDomain, AvailabilityStatus,
    BookingDomain, BookingStatus, MessageDomain, ReviewDomain, PaymentDomain,
    PaymentStatus, PaymentMethod
)
from app.domain.matching_engine import MatchingEngine
from app.core.security import hash_password, verify_password, create_access_token
from app.infrastructure.websockets.connection_manager import ws_manager
from app.core.config import settings

logger = logging.getLogger("techconnect.matching")

class AuthUseCases:
    def __init__(self, user_repo: UserRepositoryPort, tech_repo: TechnicianRepositoryPort):
        self.user_repo = user_repo
        self.tech_repo = tech_repo

    async def register(self, name: str, email: str, phone: str, password: str, role: str, category_ids: Optional[List[str]] = None) -> dict:
        existing = await self.user_repo.get_by_email(email)
        if existing:
            raise ValueError("Email already registered")
        
        user_id = str(uuid.uuid4())
        hashed = hash_password(password)
        user_role = UserRole.TECHNICIAN if role.lower() == "technician" else UserRole.CLIENT
        
        user = UserDomain(
            id=user_id,
            name=name,
            phone=phone,
            email=email,
            role=user_role,
            password_hash=hashed
        )
        created_user = await self.user_repo.create(user)

        if user_role == UserRole.TECHNICIAN:
            cats = category_ids or ["cat_plumbing"]
            tech_profile = TechnicianProfileDomain(
                id=str(uuid.uuid4()),
                user_id=user_id,
                category_ids=cats,
                latitude=14.6937,
                longitude=-17.4441,
                availability_status=AvailabilityStatus.ONLINE,
                average_rating=5.0,
                verified=True,
                user_name=name,
                user_phone=phone
            )
            await self.tech_repo.create_profile(tech_profile)

        token = create_access_token(user_id)
        return {
            "access_token": token,
            "token_type": "bearer",
            "user": {
                "id": created_user.id,
                "name": created_user.name,
                "email": created_user.email,
                "phone": created_user.phone,
                "role": created_user.role.value
            }
        }

    async def login(self, email: str, password: str) -> dict:
        user = await self.user_repo.get_by_email(email)
        if not user or not verify_password(password, user.password_hash):
            raise ValueError("Invalid email or password")
        
        token = create_access_token(user.id)
        return {
            "access_token": token,
            "token_type": "bearer",
            "user": {
                "id": user.id,
                "name": user.name,
                "email": user.email,
                "phone": user.phone,
                "role": user.role.value
            }
        }

class BookingUseCases:
    def __init__(self, booking_repo: BookingRepositoryPort, tech_repo: TechnicianRepositoryPort, user_repo: UserRepositoryPort):
        self.booking_repo = booking_repo
        self.tech_repo = tech_repo
        self.user_repo = user_repo

    async def create_booking(self, client_id: str, category_id: str, description: str, lat: float, lon: float, address_text: str, photo_url: Optional[str] = None, preferred_technician_id: Optional[str] = None) -> BookingDomain:
        booking_id = str(uuid.uuid4())
        booking = BookingDomain(
            id=booking_id,
            client_id=client_id,
            category_id=category_id,
            description=description,
            photo_url=photo_url,
            status=BookingStatus.PENDING,
            latitude=lat,
            longitude=lon,
            address_text=address_text
        )
        created_booking = await self.booking_repo.create(booking)

        # Trigger automatic matching async
        asyncio.create_task(self.run_matching_cycle(created_booking, preferred_technician_id=preferred_technician_id))
        return created_booking

    async def run_matching_cycle(self, booking: BookingDomain, preferred_technician_id: Optional[str] = None):
        try:
            from app.infrastructure.database.session import AsyncSessionLocal
            from app.infrastructure.repositories.sqlalchemy_repositories import (
                SQLAlchemyTechnicianRepository, SQLAlchemyUserRepository, SQLAlchemyBookingRepository
            )
            from app.infrastructure.database.models import MatchingLogModel
            async with AsyncSessionLocal() as session:
                tech_repo = SQLAlchemyTechnicianRepository(session)
                user_repo = SQLAlchemyUserRepository(session)
                booking_repo = SQLAlchemyBookingRepository(session)

                radius = settings.MAX_RADIUS_KM
                candidates = []
                ranked = []
                online_techs = []

                if preferred_technician_id:
                    # Target specific requested technician
                    preferred_tech = await tech_repo.get_by_user_id(preferred_technician_id)
                    if preferred_tech and (preferred_tech.availability_status == AvailabilityStatus.ONLINE or preferred_tech.user_id == "user_tech_demo") and preferred_tech.verified:
                        targets = [preferred_tech]
                    else:
                        targets = []
                else:
                    # 1. Search qualified technicians within radius
                    candidates = await tech_repo.get_available_near(
                        category_id=booking.category_id,
                        lat=booking.latitude,
                        lon=booking.longitude,
                        radius_km=radius
                    )
                    ranked = MatchingEngine.filter_and_rank_technicians(
                        candidates, booking.latitude, booking.longitude, booking.category_id, max_radius_km=radius
                    )

                    # Fallback: all online technicians with matching category
                    all_techs = await tech_repo.get_all_registered()
                    online_techs = [
                        t for t in all_techs
                        if (t.availability_status == AvailabilityStatus.ONLINE or t.user_id == "user_tech_demo")
                        and t.verified
                        and booking.category_id in (t.category_ids or [])
                    ]

                    targets = ranked if ranked else online_techs

                logger.info(
                    f"[MATCHING] booking={booking.id} category={booking.category_id} "
                    f"radius={radius}km candidates={len(candidates)} ranked={len(ranked)} "
                    f"fallback={len(online_techs)} targets={len(targets)}"
                )

                if not targets:
                    logger.warning(
                        f"[MATCHING] FAILED booking={booking.id} category={booking.category_id} "
                        f"— no qualified technician found within {radius}km"
                    )
                    # Mark booking as no_technician_found
                    await booking_repo.update_status(booking.id, "no_technician_found")
                    # Notify client
                    await ws_manager.send_personal_message(booking.client_id, {
                        "type": "NO_TECHNICIAN",
                        "booking_id": booking.id,
                        "message": "Aucun technicien disponible pour cette demande. Veuillez réessayer dans quelques instants."
                    })
                    return

                client_user = await user_repo.get_by_id(booking.client_id)
                client_name = client_user.name if client_user else "Client App"

                timeout = settings.MATCHING_RESPONSE_WINDOW_SECONDS
                match_offer = {
                    "type": "MATCH_OFFER",
                    "booking_id": booking.id,
                    "client_name": client_name,
                    "address": booking.address_text,
                    "description": booking.description,
                    "category_id": booking.category_id,
                    "timeout_seconds": timeout
                }

                from sqlalchemy import select
                accepted = False
                for tech in targets:
                    await ws_manager.send_personal_message(tech.user_id, match_offer)
                    logger.info(f"[MATCHING] OFFER sent booking={booking.id} -> tech={tech.user_id}")
                    # Log the offer
                    log = MatchingLogModel(booking_id=booking.id, technician_id=tech.user_id, status="offered")
                    session.add(log)
                    await session.commit()

                    # Wait up to timeout seconds for this tech to accept or reject
                    waited = 0
                    while waited < timeout:
                        await asyncio.sleep(1)
                        waited += 1
                        
                        # Check if booking was accepted
                        current = await booking_repo.get_by_id(booking.id)
                        if current and current.status in (BookingStatus.MATCHED, BookingStatus.IN_PROGRESS):
                            logger.info(f"[MATCHING] ACCEPTED booking={booking.id} tech={current.technician_id}")
                            log_accepted = MatchingLogModel(booking_id=booking.id, technician_id=current.technician_id, status="accepted")
                            session.add(log_accepted)
                            await session.commit()
                            accepted = True
                            break
                            
                        # Check if tech rejected
                        stmt = select(MatchingLogModel).where(
                            MatchingLogModel.booking_id == booking.id,
                            MatchingLogModel.technician_id == tech.user_id,
                            MatchingLogModel.status == "rejected"
                        )
                        result = await session.execute(stmt)
                        if result.scalars().first():
                            logger.info(f"[MATCHING] REJECTED booking={booking.id} tech={tech.user_id}")
                            break # Move to next tech immediately
                            
                        # Commit to close implicit transaction and ensure fresh DB read on next tick
                        await session.commit()
                            
                    if accepted:
                        break # Stop matching cycle entirely
                        
                    if not accepted:
                        # Log timeout if not explicitly rejected
                        stmt_rej = select(MatchingLogModel).where(
                            MatchingLogModel.booking_id == booking.id,
                            MatchingLogModel.technician_id == tech.user_id,
                            MatchingLogModel.status == "rejected"
                        )
                        res = await session.execute(stmt_rej)
                        if not res.scalars().first():
                            log_timeout = MatchingLogModel(booking_id=booking.id, technician_id=tech.user_id, status="timeout")
                            session.add(log_timeout)
                            await session.commit()

                if accepted:
                    return

                logger.warning(f"[MATCHING] EXHAUSTED booking={booking.id} — no technician accepted")
                # Mark booking as no_technician_found
                await booking_repo.update_status(booking.id, "no_technician_found")
                # Notify client
                await ws_manager.send_personal_message(booking.client_id, {
                    "type": "NO_TECHNICIAN",
                    "booking_id": booking.id,
                    "message": "Aucun technicien n'a accepté votre demande. Veuillez réessayer."
                })
        except Exception as e:
            logger.error(f"[MATCHING] ERROR booking={booking.id}: {e}", exc_info=True)

    async def update_status(self, booking_id: str, status: str, technician_id: Optional[str] = None, cancellation_reason: Optional[str] = None) -> Optional[BookingDomain]:
        booking = await self.booking_repo.get_by_id(booking_id)
        if not booking:
            return None

        # FSM: Valid transitions
        current_status = booking.status.value if hasattr(booking.status, "value") else str(booking.status)
        
        valid_transitions = {
            "pending": ["matched", "cancelled", "no_technician_found"],
            "matched": ["accepted", "in_progress", "on_site", "completed", "pending", "cancelled"],
            "accepted": ["in_progress", "on_site", "completed", "cancelled"],
            "in_progress": ["on_site", "completed", "cancelled"],
            "on_site": ["completed", "cancelled"],
            "completed": [],
            "cancelled": [],
            "no_technician_found": ["cancelled"]
        }

        if status not in valid_transitions.get(current_status, []):
            raise ValueError(f"Invalid state transition from {current_status} to {status}")

        updated = await self.booking_repo.update_status(
            booking_id=booking_id,
            status=status,
            technician_id=technician_id,
            cancellation_reason=cancellation_reason,
            expected_version=booking.version
        )
        if not updated:
            raise ValueError("Concurrency conflict: booking was modified by another transaction.")
        
        # Broadcast status update via WebSocket
        payload = {
            "type": "STATUS_UPDATE",
            "booking_id": booking_id,
            "status": updated.status.value if hasattr(updated.status, "value") else str(updated.status),
            "technician_id": updated.technician_id,
            "scheduled_eta": updated.scheduled_eta
        }
        if cancellation_reason:
            payload["cancellation_reason"] = cancellation_reason
            
        await ws_manager.broadcast_to_booking(booking_id, payload)
        if updated.client_id:
            await ws_manager.send_personal_message(updated.client_id, payload)
        if technician_id:
            await ws_manager.send_personal_message(technician_id, payload)
        
        return updated
