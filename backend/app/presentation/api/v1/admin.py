from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from datetime import datetime, timedelta
from app.infrastructure.database.session import get_db
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyUserRepository, SQLAlchemyTechnicianRepository
from app.infrastructure.database.models import UserModel, BookingModel, TechnicianProfileModel, MatchingLogModel
from app.core.security import get_current_user

router = APIRouter(prefix="/admin", tags=["Admin"])

async def require_admin(
    current_user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Dependency to check if the current user has the admin role."""
    user_repo = SQLAlchemyUserRepository(db)
    user = await user_repo.get_by_id(current_user_id)
    # the enum is handled either as string or enum
    if not user or (hasattr(user.role, 'value') and user.role.value != "admin" and user.role != "admin"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : privilèges administrateur requis."
        )
    return user

@router.get("/stats/overview")
async def get_overview_stats(
    db: AsyncSession = Depends(get_db),
    admin_user = Depends(require_admin)
):
    """Get high level KPIs for the dashboard."""
    # Online technicians
    online_techs = await db.scalar(
        select(func.count(TechnicianProfileModel.id)).where(TechnicianProfileModel.availability_status == "online")
    )
    
    # Active missions (matched, in_progress, accepted, on_site)
    active_missions = await db.scalar(
        select(func.count(BookingModel.id)).where(BookingModel.status.in_(["matched", "in_progress", "accepted", "on_site"]))
    )

    # Pending matching
    pending_missions = await db.scalar(
        select(func.count(BookingModel.id)).where(BookingModel.status == "pending")
    )

    # Failed missions past 24h
    yesterday = datetime.utcnow() - timedelta(days=1)
    failed_missions = await db.scalar(
        select(func.count(BookingModel.id)).where(
            BookingModel.status == "no_technician_found",
            BookingModel.created_at >= yesterday
        )
    )

    # Total completed today
    today = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    completed_today = await db.scalar(
        select(func.count(BookingModel.id)).where(
            BookingModel.status == "completed",
            BookingModel.created_at >= today
        )
    )

    return {
        "online_technicians": online_techs or 0,
        "active_missions": active_missions or 0,
        "pending_missions": pending_missions or 0,
        "failed_missions_24h": failed_missions or 0,
        "completed_today": completed_today or 0
    }

@router.get("/bookings")
async def get_all_bookings(
    db: AsyncSession = Depends(get_db),
    admin_user = Depends(require_admin)
):
    """List all bookings."""
    result = await db.execute(select(BookingModel).order_by(BookingModel.created_at.desc()).limit(100))
    return result.scalars().all()

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

@router.post("/technicians/{technician_user_id}/verify")
async def verify_technician(
    technician_user_id: str,
    db: AsyncSession = Depends(get_db),
    admin_user = Depends(require_admin)
):
    """Verify a technician (admin only)."""
    tech_repo = SQLAlchemyTechnicianRepository(db)
    profile = await tech_repo.get_by_user_id(technician_user_id)
    
    if not profile:
        raise HTTPException(status_code=404, detail="Technician profile not found")
        
    if profile.verified:
        return {"status": "success", "message": "Technician is already verified."}
        
    await tech_repo.update_verification_status(technician_user_id, True)
    
    return {"status": "success", "message": f"Technician {technician_user_id} verified successfully."}

@router.get("/technicians")
async def get_all_technicians(
    db: AsyncSession = Depends(get_db),
    admin_user = Depends(require_admin)
):
    """Get all technicians (admin only)."""
    tech_repo = SQLAlchemyTechnicianRepository(db)
    profiles = await tech_repo.get_all()
    return profiles
