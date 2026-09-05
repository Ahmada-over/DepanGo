from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from app.infrastructure.database.session import get_db
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyUserRepository, SQLAlchemyTechnicianRepository
from app.application.use_cases import AuthUseCases
from app.presentation.api.v1.schemas import RegisterRequest, LoginRequest, TokenResponse, FirebaseLoginRequest

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=TokenResponse)
async def register(req: RegisterRequest, db: AsyncSession = Depends(get_db)):
    user_repo = SQLAlchemyUserRepository(db)
    tech_repo = SQLAlchemyTechnicianRepository(db)
    use_case = AuthUseCases(user_repo, tech_repo)
    try:
        res = await use_case.register(
            name=req.name,
            phone=req.phone,
            password=req.password,
            role=req.role,
            email=req.email,
            category_ids=req.category_ids,
            transport_mode=req.transport_mode,
        )
        return res
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/login", response_model=TokenResponse)
async def login(request: Request, req: LoginRequest, db: AsyncSession = Depends(get_db)):
    """
    Login endpoint — rate limited to 50 requests/minute per IP.
    Accepts email or phone number with password.
    """
    from app.main import limiter

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
        res = await use_case.login(password=req.password, email=req.email, phone=req.phone)
        return res
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))

@router.post("/firebase-login", response_model=TokenResponse)
async def firebase_login(req: FirebaseLoginRequest, db: AsyncSession = Depends(get_db)):
    user_repo = SQLAlchemyUserRepository(db)
    tech_repo = SQLAlchemyTechnicianRepository(db)
    use_case = AuthUseCases(user_repo, tech_repo)
    try:
        res = await use_case.firebase_login(id_token=req.id_token, name=req.name, role=req.role)
        return res
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))
