import uuid
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.infrastructure.database.session import get_db
from app.infrastructure.repositories.sqlalchemy_repositories import (
    SQLAlchemyReviewRepository, SQLAlchemyBookingRepository, SQLAlchemyTechnicianRepository
)
from app.domain.models import ReviewDomain
from app.presentation.api.v1.schemas import ReviewCreateRequest

from app.core.security import get_current_user

router = APIRouter(prefix="/bookings/{booking_id}/review", tags=["Reviews"])

@router.post("")
async def submit_review(
    booking_id: str,
    req: ReviewCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user)
):
    review_repo = SQLAlchemyReviewRepository(db)
    booking_repo = SQLAlchemyBookingRepository(db)
    tech_repo = SQLAlchemyTechnicianRepository(db)

    booking = await booking_repo.get_by_id(booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
        
    if current_user_id not in (booking.client_id, booking.technician_id):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Accès refusé.")

    target_id = booking.technician_id if current_user_id == booking.client_id else booking.client_id

    review = ReviewDomain(
        id=str(uuid.uuid4()),
        booking_id=booking_id,
        reviewer_id=current_user_id,
        target_id=target_id,
        rating=req.rating,
        comment=req.comment or "",
        created_at=datetime.utcnow()
    )
    created = await review_repo.create(review)

    # If the review is about the technician, update their average rating
    if target_id == booking.technician_id:
        tech_profile = await tech_repo.get_by_user_id(target_id)
        if tech_profile:
            # Simple moving average update
            new_rating = round((tech_profile.average_rating * 4 + req.rating) / 5, 1)
            await tech_repo.update_rating(target_id, new_rating)

    return {
        "status": "success",
        "review_id": created.id,
        "booking_id": booking_id,
        "reviewer_id": created.reviewer_id,
        "target_id": created.target_id,
        "rating": created.rating,
        "comment": created.comment
    }
