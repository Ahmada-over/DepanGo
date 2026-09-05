from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import List

from app.infrastructure.database.session import get_db
from app.infrastructure.database.models import QuoteModel, QuoteItemModel, BookingModel, UserModel
from app.presentation.api.v1.schemas import QuoteCreate, QuoteResponse, QuoteStatusUpdate
from app.core.security import get_current_user
from app.domain.models import UserRole

router = APIRouter(prefix="/quotes", tags=["Quotes"])

@router.post("", response_model=QuoteResponse)
async def create_quote(
    quote: QuoteCreate,
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user)
):
    # Fetch current user to check role
    user_stmt = select(UserModel).where(UserModel.id == current_user_id)
    user_res = await db.execute(user_stmt)
    current_user = user_res.scalar_one_or_none()
    if not current_user or current_user.role != UserRole.TECHNICIAN.value:
        raise HTTPException(status_code=403, detail="Only technicians can create quotes")

    # Fetch booking to get client_id
    stmt = select(BookingModel).where(BookingModel.id == quote.booking_id)
    result = await db.execute(stmt)
    booking = result.scalar_one_or_none()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    new_quote = QuoteModel(
        booking_id=quote.booking_id,
        technician_id=current_user.id,
        client_id=booking.client_id,
        quote_type=quote.quote_type,
        status="draft",
        total_labor=quote.total_labor,
        total_materials=quote.total_materials,
        total_travel=quote.total_travel,
        grand_total=quote.grand_total,
        estimated_duration=quote.estimated_duration,
        notes=quote.notes
    )
    db.add(new_quote)
    await db.flush()

    for item in quote.items:
        new_item = QuoteItemModel(
            quote_id=new_quote.id,
            description=item.description,
            category=item.category,
            quantity=item.quantity,
            unit_price=item.unit_price,
            total_price=item.total_price
        )
        db.add(new_item)
    
    await db.commit()
    
    # Reload with items
    stmt_reload = select(QuoteModel).options(selectinload(QuoteModel.items)).where(QuoteModel.id == new_quote.id)
    res = await db.execute(stmt_reload)
    return res.scalar_one()

@router.get("/booking/{booking_id}", response_model=List[QuoteResponse])
async def get_quotes_for_booking(
    booking_id: str,
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user)
):
    stmt = select(QuoteModel).options(selectinload(QuoteModel.items)).where(QuoteModel.booking_id == booking_id)
    res = await db.execute(stmt)
    return res.scalars().all()

@router.patch("/{quote_id}/status", response_model=QuoteResponse)
async def update_quote_status(
    quote_id: str,
    status_update: QuoteStatusUpdate,
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user)
):
    # Fetch current user to check role
    user_stmt = select(UserModel).where(UserModel.id == current_user_id)
    user_res = await db.execute(user_stmt)
    current_user = user_res.scalar_one_or_none()

    stmt = select(QuoteModel).options(selectinload(QuoteModel.items)).where(QuoteModel.id == quote_id)
    res = await db.execute(stmt)
    quote = res.scalar_one_or_none()
    
    if not quote:
        raise HTTPException(status_code=404, detail="Quote not found")
        
    # Validation
    if status_update.status in ["accepted", "rejected"] and current_user.role != UserRole.CLIENT.value:
         raise HTTPException(status_code=403, detail="Only clients can accept/reject quotes")
         
    if status_update.status == "pending_client_approval" and current_user.role != UserRole.TECHNICIAN.value:
         raise HTTPException(status_code=403, detail="Only technicians can send quotes")

    quote.status = status_update.status
    await db.commit()
    return quote
