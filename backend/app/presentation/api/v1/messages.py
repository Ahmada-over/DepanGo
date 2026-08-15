import uuid
from datetime import datetime
from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.infrastructure.database.session import get_db
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyMessageRepository, SQLAlchemyUserRepository
from app.domain.models import MessageDomain
from app.presentation.api.v1.schemas import MessageCreateRequest, MessageResponse
from app.infrastructure.websockets.connection_manager import ws_manager

router = APIRouter(prefix="/bookings/{booking_id}/messages", tags=["Messages"])

@router.get("", response_model=List[MessageResponse])
async def get_messages(booking_id: str, db: AsyncSession = Depends(get_db)):
    repo = SQLAlchemyMessageRepository(db)
    messages = await repo.get_by_booking_id(booking_id)
    return [
        MessageResponse(
            id=m.id,
            booking_id=m.booking_id,
            sender_id=m.sender_id,
            sender_name=m.sender_name,
            content=m.content,
            sent_at=m.sent_at
        ) for m in messages
    ]

@router.post("", response_model=MessageResponse)
async def send_message(booking_id: str, req: MessageCreateRequest, sender_id: str = "user_client_demo", db: AsyncSession = Depends(get_db)):
    msg_repo = SQLAlchemyMessageRepository(db)
    user_repo = SQLAlchemyUserRepository(db)
    
    sender = await user_repo.get_by_id(sender_id)
    sender_name = sender.name if sender else "User"

    msg = MessageDomain(
        id=str(uuid.uuid4()),
        booking_id=booking_id,
        sender_id=sender_id,
        content=req.content,
        sent_at=datetime.utcnow(),
        sender_name=sender_name
    )
    created = await msg_repo.create(msg)

    # Broadcast message via WebSocket
    payload = {
        "type": "NEW_MESSAGE",
        "id": created.id,
        "booking_id": booking_id,
        "sender_id": sender_id,
        "sender_name": sender_name,
        "content": req.content,
        "sent_at": created.sent_at.isoformat()
    }
    await ws_manager.broadcast_to_booking(booking_id, payload)

    return MessageResponse(
        id=created.id,
        booking_id=created.booking_id,
        sender_id=created.sender_id,
        sender_name=sender_name,
        content=created.content,
        sent_at=created.sent_at
    )
