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

                radii_to_try = [
                    settings.MATCHING_INITIAL_RADIUS_KM,
                    settings.MATCHING_SECOND_RADIUS_KM,
                    settings.MATCHING_THIRD_RADIUS_KM,
                    settings.MATCHING_MAX_RADIUS_KM
                ]
                
                contacted_tech_ids = set()
                accepted = False

                if preferred_technician_id:
                    # Target specific requested technician first
                    preferred_tech = await tech_repo.get_by_user_id(preferred_technician_id)
                    if preferred_tech and (preferred_tech.availability_status == AvailabilityStatus.ONLINE or preferred_tech.user_id == "user_tech_demo") and preferred_tech.verified:
                        targets = [preferred_tech]
                        # Just run the logic for this single target
                        accepted = await self._send_offers_and_wait(
                            booking, targets, ws_manager, booking_repo, session, timeout=settings.MATCHING_RESPONSE_WINDOW_SECONDS
                        )
                        if accepted:
                            return

                # If no preferred tech or preferred tech rejected/timeout, run concentric matching
                timeout = settings.MATCHING_RESPONSE_WINDOW_SECONDS
                client_user = await user_repo.get_by_id(booking.client_id)
                client_name = client_user.name if client_user else "Client App"
                
                from app.infrastructure.external_apis.maps import GoogleMapsEtaService
                eta_service = GoogleMapsEtaService()
                
                for radius in radii_to_try:
                    logger.info(f"[MATCHING] Searching for technicians within {radius}km for booking {booking.id}")
                    candidates = await tech_repo.get_available_near(
                        category_id=booking.category_id,
                        lat=booking.latitude,
                        lon=booking.longitude,
                        radius_km=radius
                    )
                    
                    # Filter out those already contacted in previous smaller radii
                    new_candidates = [c for c in candidates if c.user_id not in contacted_tech_ids]
                    
                    if not new_candidates:
                        logger.info(f"[MATCHING] No new candidates found within {radius}km. Expanding search...")
                        continue
                        
                    # Fetch ETAs for all new candidates
                    tech_locations = [(c.latitude, c.longitude) for c in new_candidates]
                    eta_dict = await eta_service.get_etas(booking.latitude, booking.longitude, tech_locations)
                        
                    ranked = MatchingEngine.filter_and_rank_technicians(
                        new_candidates, booking.latitude, booking.longitude, booking.category_id, max_radius_km=radius, eta_dict=eta_dict
                    )
                    
                    if not ranked:
                        logger.info(f"[MATCHING] Candidates found but none passed ranking within {radius}km. Expanding search...")
                        continue

                    # Send offers to the ranked technicians
                    accepted = await self._send_offers_and_wait(
                        booking, ranked, ws_manager, booking_repo, session, timeout, client_name
                    )
                    
                    # Add them to contacted set so we don't spam them again in the next radius loop
                    for tech in ranked:
                        contacted_tech_ids.add(tech.user_id)
                    
                    if accepted:
                        break # Stop expanding radius
                        
                if accepted:
                    return

                logger.warning(f"[MATCHING] EXHAUSTED booking={booking.id} — max radius {settings.MATCHING_MAX_RADIUS_KM}km reached, no technician accepted")
                # Mark booking as no_technician_found
                await booking_repo.update_status(booking.id, "no_technician_found")
                # Notify client
                await ws_manager.send_personal_message(booking.client_id, {
                    "type": "NO_TECHNICIAN",
                    "booking_id": booking.id,
                    "message": "Aucun technicien n'a accepté votre demande ou n'est disponible dans votre zone. Veuillez réessayer plus tard."
                })
        except Exception as e:
            logger.error(f"[MATCHING] ERROR booking={booking.id}: {e}", exc_info=True)

    async def _send_offers_and_wait(self, booking: BookingDomain, targets: list, ws_manager, booking_repo, session, timeout: int, client_name: str = "Client App") -> bool:
        from sqlalchemy import select
        from app.infrastructure.database.models import MatchingLogModel
        
        match_offer = {
            "type": "MATCH_OFFER",
            "booking_id": booking.id,
            "client_name": client_name,
            "address": booking.address_text,
            "description": booking.description,
            "category_id": booking.category_id,
            "timeout_seconds": timeout
        }
        
        accepted = False
        for tech in targets:
            await ws_manager.send_personal_message(tech.user_id, match_offer)
            import logging
            logger = logging.getLogger("depango")
            logger.info(f"[MATCHING] OFFER sent booking={booking.id} -> tech={tech.user_id}")
            
            # Log the offer
            log = MatchingLogModel(booking_id=booking.id, technician_id=tech.user_id, status="offered")
            session.add(log)
            await session.commit()

            # Wait up to timeout seconds for this tech to accept or reject
            waited = 0
            while waited < timeout:
                import asyncio
                await asyncio.sleep(1)
                waited += 1
                
                # Check if booking was accepted
                current = await booking_repo.get_by_id(booking.id)
                from app.domain.models import BookingStatus
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
                return True
                
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
                    
        return accepted

    async def update_status(self, booking_id: str, status: str, technician_id: Optional[str] = None, cancellation_reason: Optional[str] = None) -> Optional[BookingDomain]:
        max_retries = 3
        for attempt in range(max_retries):
            booking = await self.booking_repo.get_by_id(booking_id)
            if not booking:
                return None

            # FSM: Valid transitions
            current_status = booking.status.value if hasattr(booking.status, "value") else str(booking.status)
            
            # Idempotency: if already in requested status, return success
            if current_status == status:
                return booking

            valid_transitions = {
                "pending": ["matched", "accepted", "in_progress", "cancelled", "no_technician_found"],
                "matched": ["matched", "accepted", "in_progress", "on_site", "completed", "pending", "cancelled"],
                "accepted": ["accepted", "in_progress", "on_site", "completed", "cancelled"],
                "in_progress": ["in_progress", "on_site", "completed", "cancelled"],
                "on_site": ["on_site", "completed", "cancelled"],
                "completed": ["completed"],
                "cancelled": ["cancelled"],
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
            if updated:
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
            
            # Version conflict — retry after a tiny pause
            import asyncio
            await asyncio.sleep(0.1 * (attempt + 1))
        
        raise ValueError("Concurrency conflict: booking was modified by another transaction.")
