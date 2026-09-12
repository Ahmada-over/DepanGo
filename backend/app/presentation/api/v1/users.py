from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from app.infrastructure.database.session import get_db
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyUserRepository
from app.core.security import get_current_user

router = APIRouter(prefix="/users", tags=["Users"])

class UserProfileUpdateRequest(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    category_id: Optional[str] = None
    transport_mode: Optional[str] = None

@router.get("/me")
async def get_my_profile(
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user),
):
    """Get own user profile."""
    repo = SQLAlchemyUserRepository(db)
    user = await repo.get_by_id(current_user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    created_at_str = user.created_at.isoformat() if hasattr(user.created_at, "isoformat") else str(user.created_at)
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "phone": user.phone,
        "role": user.role.value if hasattr(user.role, "value") else str(user.role),
        "created_at": created_at_str
    }

@router.put("/me")
@router.patch("/me")
async def update_profile(
    req: UserProfileUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user_id: str = Depends(get_current_user),
):
    """Update own user profile information (name, email, phone)."""
    user_repo = SQLAlchemyUserRepository(db)

    if req.name is not None or req.email is not None or req.phone is not None:
        await user_repo.update_user_info(current_user_id, name=req.name, email=req.email, phone=req.phone)

    if req.category_id or req.transport_mode:
        from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyTechnicianRepository
        tech_repo = SQLAlchemyTechnicianRepository(db)
        await tech_repo.update_profile_info(current_user_id, category_id=req.category_id, transport_mode=req.transport_mode)

    updated = await user_repo.get_by_id(current_user_id)
    created_at_str = (
        updated.created_at.isoformat()
        if updated and hasattr(updated.created_at, "isoformat")
        else str(updated.created_at) if updated else None
    )
    user_data = {
        "id": updated.id,
        "name": updated.name,
        "email": updated.email,
        "phone": updated.phone,
        "role": updated.role.value if hasattr(updated.role, "value") else str(updated.role),
        "created_at": created_at_str,
    } if updated else None

    return {
        "status": "success",
        "message": "Profil mis à jour avec succès",
        "user": user_data,
        "profile": {
            "name": updated.name,
            "email": updated.email,
            "phone": updated.phone,
        } if updated else None
    }
