from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.infrastructure.database.session import get_db
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyWalletRepository
from app.application.use_cases import WalletUseCases
from app.presentation.api.v1.schemas import WalletTopUpRequest, WalletRefundRequest
from app.core.security import get_current_user

router = APIRouter(prefix="/wallet", tags=["Wallet"])


@router.get("/balance")
async def get_balance(user_id: str = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    wallet_repo = SQLAlchemyWalletRepository(db)
    use_case = WalletUseCases(wallet_repo)
    try:
        return await use_case.get_balance(user_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get("/transactions")
async def get_transactions(user_id: str = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    wallet_repo = SQLAlchemyWalletRepository(db)
    use_case = WalletUseCases(wallet_repo)
    try:
        return await use_case.get_transactions(user_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.post("/top-up")
async def top_up(req: WalletTopUpRequest, user_id: str = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    wallet_repo = SQLAlchemyWalletRepository(db)
    use_case = WalletUseCases(wallet_repo)
    try:
        return await use_case.top_up(user_id, req.amount)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/refund")
async def request_refund(req: WalletRefundRequest, user_id: str = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    wallet_repo = SQLAlchemyWalletRepository(db)
    use_case = WalletUseCases(wallet_repo)
    try:
        return await use_case.request_refund(user_id, req.booking_id)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
