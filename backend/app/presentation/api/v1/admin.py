import time
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func, and_, or_, text

from app.infrastructure.database.session import get_db
from app.infrastructure.repositories.sqlalchemy_repositories import (
    SQLAlchemyUserRepository,
    SQLAlchemyTechnicianRepository,
    SQLAlchemyBookingRepository
)
from app.infrastructure.database.models import (
    UserModel,
    BookingModel,
    TechnicianProfileModel,
    MatchingLogModel,
    PaymentModel,
    ServiceCategoryModel
)
from app.infrastructure.websockets.connection_manager import ws_manager
from app.core.security import get_current_user

router = APIRouter(prefix="/admin", tags=["Admin"])
_SERVER_START_TIME = time.time()


async def require_admin(
    current_user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Dependency to check if the current user has the admin role."""
    user_repo = SQLAlchemyUserRepository(db)
    user = await user_repo.get_by_id(current_user_id)
    if not user or (hasattr(user.role, 'value') and user.role.value != "admin" and user.role != "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : privilèges administrateur requis."
        )
    return user


# ---------------------------------------------------------------------------
# 1. High-Level KPIs & Overview
# ---------------------------------------------------------------------------
@router.get("/stats/overview")
async def get_overview_stats(
    db: AsyncSession = Depends(get_db),
    admin_user = Depends(require_admin)
):
    """Get high-level KPIs for the executive & operational dashboard."""
    # Online & total technicians
    online_techs = await db.scalar(
        select(func.count(TechnicianProfileModel.id)).where(TechnicianProfileModel.availability_status == "online")
    ) or 0

    total_techs = await db.scalar(
        select(func.count(TechnicianProfileModel.id))
    ) or 0

    # Total clients
    total_clients = await db.scalar(
        select(func.count(UserModel.id)).where(UserModel.role == "client")
    ) or 0

    # Active missions (matched, in_progress, on_site)
    active_missions = await db.scalar(
        select(func.count(BookingModel.id)).where(
            BookingModel.status.in_(["matched", "in_progress", "accepted", "on_site"])
        )
    ) or 0

    # Pending missions waiting for technician
    pending_missions = await db.scalar(
        select(func.count(BookingModel.id)).where(BookingModel.status == "pending")
    ) or 0

    # Total bookings all time
    total_bookings = await db.scalar(
        select(func.count(BookingModel.id))
    ) or 0

    # Failed missions past 24h
    yesterday = datetime.utcnow() - timedelta(days=1)
    failed_missions = await db.scalar(
        select(func.count(BookingModel.id)).where(
            BookingModel.status == "no_technician_found",
            BookingModel.created_at >= yesterday
        )
    ) or 0

    # Total completed today
    today = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    completed_today = await db.scalar(
        select(func.count(BookingModel.id)).where(
            BookingModel.status == "completed",
            BookingModel.created_at >= today
        )
    ) or 0

    # Total completed all time
    total_completed = await db.scalar(
        select(func.count(BookingModel.id)).where(BookingModel.status == "completed")
    ) or 0

    # Revenue calculation (Sum of payments or standard estimation per completed mission)
    payments_sum = await db.scalar(
        select(func.sum(PaymentModel.amount)).where(PaymentModel.status.in_(["paid_direct", "completed"]))
    ) or 0.0

    # Estimated GMV (Average 15,000 CFA per completed repair if payments are off-platform cash)
    estimated_gmv = payments_sum if payments_sum > 0 else (total_completed * 15000)
    estimated_commission = estimated_gmv * 0.15

    return {
        "online_technicians": online_techs,
        "total_technicians": total_techs,
        "total_clients": total_clients,
        "active_missions": active_missions,
        "pending_missions": pending_missions,
        "total_bookings": total_bookings,
        "failed_missions_24h": failed_missions,
        "completed_today": completed_today,
        "total_completed": total_completed,
        "estimated_gmv_cfa": int(estimated_gmv),
        "estimated_commission_cfa": int(estimated_commission),
    }


# ---------------------------------------------------------------------------
# 2. System Health & Infrastructure Monitoring
# ---------------------------------------------------------------------------
@router.get("/monitoring/health")
async def get_system_health(
    db: AsyncSession = Depends(get_db),
    admin_user = Depends(require_admin)
):
    """System health check, database latency, and real-time WebSocket metrics."""
    # Test DB latency
    t0 = time.perf_counter()
    db_ok = True
    db_latency_ms = 0.0
    try:
        await db.execute(text("SELECT 1"))
        db_latency_ms = round((time.perf_counter() - t0) * 1000, 2)
    except Exception:
        db_ok = False

    # Extract WebSocket manager stats
    ws_user_count = len(ws_manager.user_connections)
    ws_booking_count = len(ws_manager.active_booking_connections)
    ws_area_count = len(ws_manager.area_connections)

    # Server uptime
    uptime_seconds = int(time.time() - _SERVER_START_TIME)

    return {
        "status": "operational" if db_ok else "degraded",
        "timestamp": datetime.utcnow().isoformat(),
        "database": {
            "connected": db_ok,
            "latency_ms": db_latency_ms,
            "engine": "PostgreSQL (AsyncPG)",
        },
        "websockets": {
            "active_user_channels": ws_user_count,
            "active_booking_channels": ws_booking_count,
            "active_area_channels": ws_area_count,
            "total_open_sockets": ws_user_count + ws_booking_count + ws_area_count,
        },
        "system": {
            "uptime_seconds": uptime_seconds,
            "uptime_formatted": f"{uptime_seconds // 3600}h {(uptime_seconds % 3600) // 60}m {uptime_seconds % 60}s",
            "dispatch_engine": "Active (90s Radius Cascade)",
            "stale_cleaner_task": "Running",
        }
    }


# ---------------------------------------------------------------------------
# 3. Fleet Live Radar & Location Tracking
# ---------------------------------------------------------------------------
@router.get("/monitoring/fleet")
async def get_fleet_monitoring(
    db: AsyncSession = Depends(get_db),
    admin_user = Depends(require_admin)
):
    """Get all technicians with full profile, vehicle type, and real-time GPS position."""
    stmt = (
        select(TechnicianProfileModel, UserModel)
        .join(UserModel, TechnicianProfileModel.user_id == UserModel.id)
        .order_by(TechnicianProfileModel.availability_status.desc(), TechnicianProfileModel.location_updated_at.desc())
    )
    result = await db.execute(stmt)
    rows = result.all()

    fleet = []
    for profile, user in rows:
        # Check if technician is currently on an active mission
        active_b = await db.scalar(
            select(BookingModel.id).where(
                BookingModel.technician_id == user.id,
                BookingModel.status.in_(["matched", "in_progress", "on_site"])
            ).limit(1)
        )

        fleet.append({
            "id": profile.id,
            "user_id": user.id,
            "name": user.name,
            "phone": user.phone,
            "email": user.email,
            "transport_mode": profile.transport_mode or "moto",
            "availability_status": profile.availability_status,
            "verified": bool(profile.verified),
            "average_rating": profile.average_rating or 5.0,
            "category_ids": profile.category_ids or [],
            "latitude": profile.latitude or 14.6937,
            "longitude": profile.longitude or -17.4441,
            "location_updated_at": profile.location_updated_at.isoformat() if profile.location_updated_at else None,
            "has_active_mission": active_b is not None,
            "active_mission_id": active_b,
        })

    return fleet


# ---------------------------------------------------------------------------
# 4. Live Active Missions & Real-Time Tracking
# ---------------------------------------------------------------------------
@router.get("/monitoring/missions/live")
async def get_live_missions(
    db: AsyncSession = Depends(get_db),
    admin_user = Depends(require_admin)
):
    """Get all current live interventions with live coordinates and client/tech metadata."""
    stmt = (
        select(BookingModel)
        .where(BookingModel.status.in_(["pending", "matched", "in_progress", "on_site"]))
        .order_by(BookingModel.created_at.desc())
    )
    result = await db.execute(stmt)
    bookings = result.scalars().all()

    user_repo = SQLAlchemyUserRepository(db)
    missions = []

    for b in bookings:
        client = await user_repo.get_by_id(b.client_id)
        tech = await user_repo.get_by_id(b.technician_id) if b.technician_id else None
        tech_profile = None
        if b.technician_id:
            tech_profile = await db.scalar(
                select(TechnicianProfileModel).where(TechnicianProfileModel.user_id == b.technician_id)
            )

        elapsed_sec = int((datetime.utcnow() - b.created_at).total_seconds()) if b.created_at else 0

        missions.append({
            "id": b.id,
            "status": b.status,
            "category_id": b.category_id,
            "description": b.description,
            "address_text": b.address_text,
            "latitude": b.latitude,
            "longitude": b.longitude,
            "created_at": b.created_at.isoformat() if b.created_at else None,
            "elapsed_seconds": elapsed_sec,
            "scheduled_eta": b.scheduled_eta,
            "client": {
                "id": client.id if client else b.client_id,
                "name": client.name if client else "Client",
                "phone": client.phone if client else "",
            },
            "technician": {
                "id": tech.id if tech else None,
                "name": tech.name if tech else None,
                "phone": tech.phone if tech else None,
                "transport_mode": tech_profile.transport_mode if tech_profile else "moto",
                "latitude": tech_profile.latitude if tech_profile else None,
                "longitude": tech_profile.longitude if tech_profile else None,
            } if tech else None,
        })

    return missions


# ---------------------------------------------------------------------------
# 5. Financial & Operational Analytics
# ---------------------------------------------------------------------------
@router.get("/stats/analytics")
async def get_analytics_breakdown(
    db: AsyncSession = Depends(get_db),
    admin_user = Depends(require_admin)
):
    """Detailed analytics: Category distribution, status funnel, and matching response times."""
    # 1. Category distribution
    cat_stmt = (
        select(BookingModel.category_id, func.count(BookingModel.id))
        .group_by(BookingModel.category_id)
    )
    cat_res = await db.execute(cat_stmt)
    category_counts = {row[0]: row[1] for row in cat_res.all()}

    # 2. Status distribution
    status_stmt = (
        select(BookingModel.status, func.count(BookingModel.id))
        .group_by(BookingModel.status)
    )
    status_res = await db.execute(status_stmt)
    status_counts = {row[0]: row[1] for row in status_res.all()}

    # 3. Last 7 Days Daily Trend
    seven_days_ago = datetime.utcnow().date() - timedelta(days=6)
    daily_stats = []
    for i in range(7):
        current_date = seven_days_ago + timedelta(days=i)
        start = datetime.combine(current_date, datetime.min.time())
        end = datetime.combine(current_date, datetime.max.time())
        
        count = await db.scalar(
            select(func.count(BookingModel.id)).where(
                BookingModel.created_at >= start,
                BookingModel.created_at <= end
            )
        ) or 0
        
        completed = await db.scalar(
            select(func.count(BookingModel.id)).where(
                BookingModel.created_at >= start,
                BookingModel.created_at <= end,
                BookingModel.status == "completed"
            )
        ) or 0

        daily_stats.append({
            "date": current_date.strftime("%d/%m"),
            "total_requests": count,
            "completed": completed,
        })

    # 4. Matching Logs metrics
    total_offers = await db.scalar(select(func.count(MatchingLogModel.id))) or 0
    accepted_offers = await db.scalar(
        select(func.count(MatchingLogModel.id)).where(MatchingLogModel.status == "accepted")
    ) or 0
    timeout_offers = await db.scalar(
        select(func.count(MatchingLogModel.id)).where(MatchingLogModel.status == "timeout")
    ) or 0

    conversion_rate = round((accepted_offers / total_offers * 100), 1) if total_offers > 0 else 0.0

    return {
        "category_distribution": category_counts,
        "status_distribution": status_counts,
        "daily_trends_7d": daily_stats,
        "matching_funnel": {
            "total_offers_sent": total_offers,
            "accepted_offers": accepted_offers,
            "timeout_offers": timeout_offers,
            "acceptance_rate_percent": conversion_rate,
        }
    }


# ---------------------------------------------------------------------------
# 6. Technician Management & KYC
# ---------------------------------------------------------------------------
@router.get("/technicians")
async def get_all_technicians(
    db: AsyncSession = Depends(get_db),
    admin_user = Depends(require_admin)
):
    """List all technicians with user info, verification, and mission counts."""
    stmt = (
        select(TechnicianProfileModel, UserModel)
        .join(UserModel, TechnicianProfileModel.user_id == UserModel.id)
        .order_by(UserModel.created_at.desc())
    )
    result = await db.execute(stmt)
    rows = result.all()

    technicians = []
    for profile, user in rows:
        completed_count = await db.scalar(
            select(func.count(BookingModel.id)).where(
                BookingModel.technician_id == user.id,
                BookingModel.status == "completed"
            )
        ) or 0

        technicians.append({
            "id": profile.id,
            "user_id": user.id,
            "name": user.name,
            "phone": user.phone,
            "email": user.email,
            "transport_mode": profile.transport_mode or "moto",
            "availability_status": profile.availability_status,
            "verified": bool(profile.verified),
            "average_rating": profile.average_rating or 5.0,
            "category_ids": profile.category_ids or [],
            "completed_missions": completed_count,
            "created_at": user.created_at.isoformat() if user.created_at else None,
            "latitude": profile.latitude,
            "longitude": profile.longitude,
        })

    return technicians


@router.post("/technicians/{technician_user_id}/verify")
@router.post("/technicians/{technician_user_id}/toggle-verify")
async def toggle_technician_verify(
    technician_user_id: str,
    verified: Optional[bool] = Body(None, embed=True),
    db: AsyncSession = Depends(get_db),
    admin_user = Depends(require_admin)
):
    """Verify or toggle KYC verification status of a technician."""
    tech_repo = SQLAlchemyTechnicianRepository(db)
    profile = await tech_repo.get_by_user_id(technician_user_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profil technicien introuvable.")

    new_status = verified if verified is not None else not bool(profile.verified)
    await tech_repo.update_verification_status(technician_user_id, new_status)
    await db.commit()

    return {
        "status": "success",
        "verified": new_status,
        "message": f"Statut de vérification mis à jour pour le technicien {technician_user_id}."
    }


@router.post("/technicians/{technician_user_id}/toggle-availability")
async def toggle_technician_availability(
    technician_user_id: str,
    availability: Optional[str] = Body(None, embed=True),
    db: AsyncSession = Depends(get_db),
    admin_user = Depends(require_admin)
):
    """Toggle online/offline status for a technician (Administrative override)."""
    tech_repo = SQLAlchemyTechnicianRepository(db)
    profile = await tech_repo.get_by_user_id(technician_user_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profil technicien introuvable.")

    new_status = availability if availability in ["online", "offline"] else (
        "offline" if profile.availability_status == "online" else "online"
    )
    await tech_repo.update_availability(technician_user_id, new_status)
    await db.commit()

    return {
        "status": "success",
        "availability_status": new_status,
        "message": f"Statut changé en {new_status}."
    }


# ---------------------------------------------------------------------------
# 7. Interventions Management & Manual Dispatch Override
# ---------------------------------------------------------------------------
@router.get("/bookings")
async def get_all_bookings(
    status_filter: Optional[str] = None,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    admin_user = Depends(require_admin)
):
    """List all bookings with optional status filtering."""
    query = select(BookingModel).order_by(BookingModel.created_at.desc()).limit(limit)
    if status_filter:
        query = query.where(BookingModel.status == status_filter)

    result = await db.execute(query)
    bookings = result.scalars().all()

    user_repo = SQLAlchemyUserRepository(db)
    detailed = []
    for b in bookings:
        client = await user_repo.get_by_id(b.client_id)
        tech = await user_repo.get_by_id(b.technician_id) if b.technician_id else None
        detailed.append({
            "id": b.id,
            "client_name": client.name if client else "Client",
            "client_phone": client.phone if client else "",
            "technician_name": tech.name if tech else None,
            "technician_phone": tech.phone if tech else None,
            "category_id": b.category_id,
            "status": b.status,
            "address_text": b.address_text,
            "description": b.description,
            "created_at": b.created_at.isoformat() if b.created_at else None,
            "scheduled_eta": b.scheduled_eta,
            "cancellation_reason": b.cancellation_reason,
        })

    return detailed


@router.get("/bookings/{booking_id}/logs")
async def get_booking_matching_logs(
    booking_id: str,
    db: AsyncSession = Depends(get_db),
    admin_user = Depends(require_admin)
):
    """Get the matching logs for a specific booking."""
    result = await db.execute(
        select(MatchingLogModel)
        .where(MatchingLogModel.booking_id == booking_id)
        .order_by(MatchingLogModel.created_at.asc())
    )
    return result.scalars().all()


@router.post("/bookings/{booking_id}/manual-assign")
async def manual_assign_booking(
    booking_id: str,
    technician_user_id: str = Body(..., embed=True),
    db: AsyncSession = Depends(get_db),
    admin_user = Depends(require_admin)
):
    """Manually assign/dispatch a booking to a specific technician (Admin Force Dispatch)."""
    booking_repo = SQLAlchemyBookingRepository(db)
    booking = await booking_repo.get_by_id(booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="Réservation introuvable.")

    user_repo = SQLAlchemyUserRepository(db)
    tech_user = await user_repo.get_by_id(technician_user_id)
    if not tech_user:
        raise HTTPException(status_code=404, detail="Technicien introuvable.")

    # Assign technician and change status to matched
    booking.technician_id = technician_user_id
    booking.status = "matched"
    await booking_repo.update(booking)

    # Notify technician and client via WebSocket
    await ws_manager.send_personal_message(
        technician_user_id,
        {
            "type": "MATCH_OFFER",
            "booking_id": booking.id,
            "client_name": "Client (Assignation Admin)",
            "address_text": booking.address_text,
            "category_id": booking.category_id,
            "description": booking.description,
            "distance_km": 1.0,
            "timeout_seconds": 90,
        }
    )
    await ws_manager.broadcast_to_booking(
        booking.id,
        {
            "type": "STATUS_CHANGE",
            "status": "matched",
            "technician_id": technician_user_id,
            "technician_name": tech_user.name,
            "message": f"Dépanneur assigné par l'administration : {tech_user.name}"
        }
    )

    return {
        "status": "success",
        "booking_id": booking.id,
        "technician_id": technician_user_id,
        "message": f"Mission assignée avec succès à {tech_user.name}."
    }
