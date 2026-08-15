from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
import uuid
from datetime import datetime

from app.infrastructure.database.session import get_db
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemySubscriptionRepository
from app.domain.models import SubscriptionDomain
from app.presentation.api.v1.schemas import SubscriptionCreateRequest, SubscriptionResponse
from app.core.security import get_current_user

router = APIRouter(prefix="/subscriptions", tags=["Subscriptions"])

@router.post("/", response_model=SubscriptionResponse)
async def create_subscription(
    req: SubscriptionCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user)
):
    repo = SQLAlchemySubscriptionRepository(db)
    
    # Check if already has an active subscription
    active = await repo.get_active_by_technician(current_user_id)
    if active and active.plan_name == req.plan_name:
        return active
        
    subscription = SubscriptionDomain(
        id=str(uuid.uuid4()),
        technician_id=current_user_id,
        plan_name=req.plan_name,
        status="active",
        start_date=datetime.utcnow()
    )
    created = await repo.create(subscription)
    
    return SubscriptionResponse(
        id=created.id,
        technician_id=created.technician_id,
        plan_name=created.plan_name,
        status=created.status,
        start_date=created.start_date,
        end_date=created.end_date
    )

@router.get("/me", response_model=SubscriptionResponse)
async def get_my_subscription(
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user)
):
    repo = SQLAlchemySubscriptionRepository(db)
    active = await repo.get_active_by_technician(current_user_id)
    if not active:
        raise HTTPException(status_code=404, detail="No active subscription found")
        
    return SubscriptionResponse(
        id=active.id,
        technician_id=active.technician_id,
        plan_name=active.plan_name,
        status=active.status,
        start_date=active.start_date,
        end_date=active.end_date
    )
