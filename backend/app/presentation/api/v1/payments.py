import uuid
from datetime import datetime
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.infrastructure.database.session import get_db
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyPaymentRepository, SQLAlchemyBookingRepository
from app.domain.models import PaymentDomain, PaymentStatus, PaymentMethod
from app.presentation.api.v1.schemas import PaymentCreateRequest

router = APIRouter(prefix="/bookings/{booking_id}/payment", tags=["Payments"])

@router.post("")
async def process_direct_payment(booking_id: str, req: PaymentCreateRequest, db: AsyncSession = Depends(get_db)):
    pay_repo = SQLAlchemyPaymentRepository(db)
    booking_repo = SQLAlchemyBookingRepository(db)

    payment = PaymentDomain(
        id=str(uuid.uuid4()),
        booking_id=booking_id,
        amount=req.amount,
        status=PaymentStatus.PAID_DIRECT,
        method=PaymentMethod(req.method) if req.method in PaymentMethod._value2member_map_ else PaymentMethod.DIRECT_CASH,
        created_at=datetime.utcnow()
    )
    created = await pay_repo.create(payment)
    await booking_repo.update_status(booking_id, "completed")

    return {
        "status": "success",
        "payment_id": created.id,
        "booking_id": booking_id,
        "amount": created.amount,
        "payment_method": created.method.value,
        "message": "Paiement direct au technicien enregistré avec succès."
    }
