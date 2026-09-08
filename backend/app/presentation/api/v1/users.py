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
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "phone": user.phone,
        "role": user.role.value if hasattr(user.role, "value") else str(user.role),
        "created_at": user.created_at
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

    if req.name or req.email or req.phone:
        await user_repo.update_user_info(current_user_id, name=req.name, email=req.email, phone=req.phone)

    updated = await user_repo.get_by_id(current_user_id)
    return {
        "status": "success",
        "message": "Profil mis à jour avec succès",
        "profile": {
            "name": updated.name,
            "email": updated.email,
            "phone": updated.phone,
        } if updated else None
    }
