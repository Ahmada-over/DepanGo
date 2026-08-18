from fastapi import APIRouter, Depends, HTTPException, status, Request, UploadFile, File
from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from app.infrastructure.database.session import get_db
from app.infrastructure.repositories.sqlalchemy_repositories import (
    SQLAlchemyBookingRepository, SQLAlchemyTechnicianRepository, SQLAlchemyUserRepository
)
from app.application.use_cases import BookingUseCases
from app.presentation.api.v1.schemas import BookingCreateRequest, BookingStatusUpdateRequest, BookingResponse
from app.core.security import get_current_user

router = APIRouter(prefix="/bookings", tags=["Bookings"])


def _booking_to_response(booking) -> BookingResponse:
    """Helper to avoid duplicating BookingResponse construction."""
    return BookingResponse(
        id=booking.id,
        client_id=booking.client_id,
        client_name=booking.client_name,
        category_id=booking.category_id,
        description=booking.description,
        photo_url=booking.photo_url,
        status=booking.status.value if hasattr(booking.status, "value") else str(booking.status),
        latitude=booking.latitude,
        longitude=booking.longitude,
        address_text=booking.address_text,
        technician_id=booking.technician_id,
        scheduled_eta=booking.scheduled_eta,
        cancellation_reason=booking.cancellation_reason,
        created_at=booking.created_at,
    )


@router.post("", response_model=BookingResponse)
async def create_booking(
    request: Request,
    req: BookingCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user),
):
    """Create a booking — authenticated client only. Rate limited."""
    from app.main import limiter
    
    @limiter.limit("50/minute")
    async def _inner(request: Request):
        pass

    try:
        await _inner(request)
    except Exception:
        raise HTTPException(status_code=429, detail="Trop de demandes de réservation. Réessayez plus tard.")

    booking_repo = SQLAlchemyBookingRepository(db)
    tech_repo = SQLAlchemyTechnicianRepository(db)
    user_repo = SQLAlchemyUserRepository(db)
    use_case = BookingUseCases(booking_repo, tech_repo, user_repo)

    booking = await use_case.create_booking(
        client_id=current_user_id,
        category_id=req.category_id,
        description=req.description,
        lat=req.latitude,
        lon=req.longitude,
        address_text=req.address_text,
        photo_url=req.photo_url,
        preferred_technician_id=req.preferred_technician_id,
    )
    return _booking_to_response(booking)


@router.get("/user/{user_id}", response_model=List[BookingResponse])
async def list_user_bookings(
    user_id: str,
    role: str = "client",
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user),
):
    """List bookings for a user — user can only see their own bookings."""
    if current_user_id != user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé : vous ne pouvez consulter que vos propres réservations.",
        )
    repo = SQLAlchemyBookingRepository(db)
    bookings = await repo.get_by_user(user_id, role)
    return [_booking_to_response(b) for b in bookings]


@router.get("/{booking_id}", response_model=BookingResponse)
async def get_booking(
    booking_id: str,
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user),
):
    """Get a booking by ID — must be client or assigned technician."""
    repo = SQLAlchemyBookingRepository(db)
    booking = await repo.get_by_id(booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    # Authorization: only client or assigned technician may read
    if current_user_id not in (booking.client_id, booking.technician_id):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Accès refusé.")
    return _booking_to_response(booking)


@router.patch("/{booking_id}/status", response_model=BookingResponse)
async def update_booking_status(
    booking_id: str,
    req: BookingStatusUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user),
):
    """Update booking status — only assigned technician or client may do this."""
    booking_repo = SQLAlchemyBookingRepository(db)
    existing = await booking_repo.get_by_id(booking_id)
    if not existing:
        raise HTTPException(status_code=404, detail=f"Booking '{booking_id}' not found")
    tech_repo = SQLAlchemyTechnicianRepository(db)
    user_repo = SQLAlchemyUserRepository(db)
    current_user_obj = await user_repo.get_by_id(current_user_id)
    is_admin = current_user_obj and hasattr(current_user_obj.role, 'value') and current_user_obj.role.value == "admin" or current_user_obj.role == "admin"
    if not is_admin and current_user_id not in (existing.client_id, existing.technician_id, req.technician_id):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Accès refusé.")

    use_case = BookingUseCases(booking_repo, tech_repo, user_repo)
    try:
        updated = await use_case.update_status(
            booking_id, 
            req.status, 
            req.technician_id,
            req.cancellation_reason
        )
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))
        
    if not updated:
        raise HTTPException(status_code=404, detail=f"Booking '{booking_id}' not found")
    return _booking_to_response(updated)


@router.post("/upload_photo")
async def upload_booking_photo(
    request: Request,
    file: UploadFile = File(...),
):
    """Upload a photo for a booking or technician profile."""
    # 1. Validate MIME type
    allowed_mimes = ["image/jpeg", "image/png", "image/webp", "image/jpg", "application/octet-stream"]
    content_type = file.content_type or "image/jpeg"
    if content_type not in allowed_mimes and not file.filename.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')):
        raise HTTPException(status_code=400, detail="Format de fichier non supporté. Utilisez JPG, PNG ou WEBP.")
        
    # 2. Validate Size (10MB max)
    contents = await file.read()
    max_size_mb = 10
    if len(contents) > max_size_mb * 1024 * 1024:
        raise HTTPException(status_code=400, detail=f"Fichier trop volumineux. Taille maximum : {max_size_mb} MB.")
        
    import uuid
    import os
    
    upload_dir = "uploads"
    os.makedirs(upload_dir, exist_ok=True)
    
    ext = file.filename.split(".")[-1] if "." in file.filename else "jpg"
    filename = f"{uuid.uuid4()}.{ext}"
    filepath = os.path.join(upload_dir, filename)
    
    with open(filepath, "wb") as f:
        f.write(contents)
        
    return {
        "status": "success",
        "photo_url": f"/static/uploads/{filename}",
        "filename": filename
    }

@router.post("/{booking_id}/decline")
async def decline_booking_offer(
    booking_id: str,
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user),
):
    """Technician explicitly declines a booking offer."""
    from sqlalchemy import select, update
    from app.infrastructure.database.models import MatchingLogModel

    booking_repo = SQLAlchemyBookingRepository(db)
    existing = await booking_repo.get_by_id(booking_id)
    if not existing:
        raise HTTPException(status_code=404, detail="Booking not found")

    # Check if a matching log already exists
    stmt_check = select(MatchingLogModel).where(
        MatchingLogModel.booking_id == booking_id,
        MatchingLogModel.technician_id == current_user_id
    )
    result = await db.execute(stmt_check)
    existing_log = result.scalars().first()

    if existing_log:
        existing_log.status = "rejected"
    else:
        new_log = MatchingLogModel(
            booking_id=booking_id,
            technician_id=current_user_id,
            status="rejected"
        )
        db.add(new_log)
    
    await db.commit()
    
    return {"message": "Offer declined successfully"}

