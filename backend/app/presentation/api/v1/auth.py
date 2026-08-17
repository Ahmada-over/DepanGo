from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from app.infrastructure.database.session import get_db
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyUserRepository, SQLAlchemyTechnicianRepository
from app.application.use_cases import AuthUseCases
from app.presentation.api.v1.schemas import RegisterRequest, LoginRequest, TokenResponse

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=TokenResponse)
async def register(req: RegisterRequest, db: AsyncSession = Depends(get_db)):
    user_repo = SQLAlchemyUserRepository(db)
    tech_repo = SQLAlchemyTechnicianRepository(db)
    use_case = AuthUseCases(user_repo, tech_repo)
    try:
        res = await use_case.register(
            name=req.name,
            email=req.email,
            phone=req.phone,
            password=req.password,
            role=req.role,
            category_ids=req.category_ids,
        )
        return res
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/login", response_model=TokenResponse)
async def login(request: Request, req: LoginRequest, db: AsyncSession = Depends(get_db)):
    """
    Login endpoint — rate limited to 100 requests/minute per IP.
    The limiter is applied via the app-level state set in main.py.
    """
    from app.main import limiter  # import here to avoid circular imports

    @limiter.limit("50/minute")
    async def _inner(request: Request):
        pass

    try:
        await _inner(request)
    except Exception:
        raise HTTPException(status_code=429, detail="Trop de tentatives. Réessayez plus tard.")

    user_repo = SQLAlchemyUserRepository(db)
    tech_repo = SQLAlchemyTechnicianRepository(db)
    use_case = AuthUseCases(user_repo, tech_repo)
    try:
        res = await use_case.login(email=req.email, password=req.password)
        return res
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))
