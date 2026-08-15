from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from app.infrastructure.database.session import get_db
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyTechnicianRepository
from app.presentation.api.v1.schemas import AvailabilityUpdateRequest, LocationUpdateRequest, TransportUpdateRequest
from app.infrastructure.websockets.connection_manager import ws_manager
from app.core.security import get_current_user

router = APIRouter(prefix="/technicians", tags=["Technicians"])


@router.get("", response_model=List[dict])
async def list_registered_technicians(
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user),
):
    """List all registered technicians. Must be authenticated."""
    repo = SQLAlchemyTechnicianRepository(db)
    techs = await repo.get_all_registered()
    return [
        {
            "id": profile.id,
            "user_id": profile.user_id,
            "name": profile.user_name,
            "phone": profile.user_phone,
            "category_ids": profile.category_ids,
            "latitude": profile.latitude,
            "longitude": profile.longitude,
            "availability_status": profile.availability_status.value if hasattr(profile.availability_status, "value") else str(profile.availability_status),
            "average_rating": profile.average_rating,
            "verified": profile.verified,
            "transport_mode": profile.transport_mode,
        }
        for profile in techs
    ]


@router.get("/nearby", response_model=List[dict])
async def get_nearby_technicians(
    category_id: str,
    lat: float,
    lng: float,
    radius_km: float = 25.0,
    db: AsyncSession = Depends(get_db)
):
    """Get online, verified technicians near a location for the real-time map."""
    repo = SQLAlchemyTechnicianRepository(db)
    techs = await repo.get_available_near(category_id, lat, lng, radius_km)
    
    return [
        {
            "id": profile.id,
            "user_id": profile.user_id,
            "name": profile.user_name,
            "category_ids": profile.category_ids,
            "latitude": profile.latitude,
            "longitude": profile.longitude,
            "average_rating": profile.average_rating,
            "transport_mode": profile.transport_mode,
            "location_updated_at": profile.location_updated_at.isoformat() if profile.location_updated_at else None
        }
        for profile in techs
    ]

@router.patch("/me/availability")
async def toggle_availability(
    req: AvailabilityUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user),
):
    """Toggle technician online/offline status."""
    repo = SQLAlchemyTechnicianRepository(db)
    await repo.update_availability(current_user_id, req.status)
    return {"status": "success", "availability_status": req.status}


@router.post("/me/location")
async def update_location(
    req: LocationUpdateRequest,
    booking_id: str = None,
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user),
):
    """Update technician GPS location, broadcast to booking WS if active, and area WS."""
    repo = SQLAlchemyTechnicianRepository(db)
    await repo.update_location(current_user_id, req.latitude, req.longitude)

    # Broadcast to booking WS if an active booking is provided
    if booking_id:
        payload = {
            "type": "LOCATION_UPDATE",
            "booking_id": booking_id,
            "latitude": req.latitude,
            "longitude": req.longitude,
            "eta": "12 mins",
        }
        await ws_manager.broadcast_to_booking(booking_id, payload)

    # Broadcast to area WS for real-time map tracking
    profile = await repo.get_by_user_id(current_user_id)
    if profile and profile.availability_status == "online":
        broadcast_cats = set(profile.category_ids)
        broadcast_cats.add("cat_express")
        for cat in broadcast_cats:
            payload = {
                "type": "LOCATION_UPDATE",
                "technician_id": profile.id,
                "user_id": profile.user_id,
                "name": profile.user_name,
                "average_rating": profile.average_rating,
                "transport_mode": profile.transport_mode,
                "latitude": req.latitude,
                "longitude": req.longitude,
                "category_id": cat
            }
            await ws_manager.broadcast_to_area(cat, payload)

    return {"status": "success", "latitude": req.latitude, "longitude": req.longitude}


@router.get("/me")
async def get_my_profile(
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user),
):
    """Get own technician profile."""
    repo = SQLAlchemyTechnicianRepository(db)
    profile = await repo.get_by_user_id(current_user_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Technician profile not found")
    return {
        "id": profile.id,
        "user_id": profile.user_id,
        "name": profile.user_name,
        "phone": profile.user_phone,
        "category_ids": profile.category_ids,
        "latitude": profile.latitude,
        "longitude": profile.longitude,
        "availability_status": profile.availability_status.value if hasattr(profile.availability_status, "value") else str(profile.availability_status),
        "average_rating": profile.average_rating,
        "verified": profile.verified,
        "transport_mode": profile.transport_mode,
    }

@router.patch("/me/transport")
async def update_transport_mode(
    req: TransportUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user),
):
    """Update technician transport mode."""
    repo = SQLAlchemyTechnicianRepository(db)
    await repo.update_transport_mode(current_user_id, req.transport_mode)
    return {"status": "success", "transport_mode": req.transport_mode}


class ProfileUpdateRequest(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    category_ids: Optional[List[str]] = None


@router.patch("/me/profile")
async def update_profile(
    req: ProfileUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user),
):
    """Update own profile information (name, email, phone, categories)."""
    tech_repo = SQLAlchemyTechnicianRepository(db)

    if req.name or req.email or req.phone:
        await tech_repo.update_user_info(current_user_id, req.name, req.email, req.phone)

    if req.category_ids is not None:
        await tech_repo.update_categories(current_user_id, req.category_ids)

    return {"status": "success", "message": "Profile updated successfully"}
