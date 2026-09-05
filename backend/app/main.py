from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from app.core.config import settings
from app.infrastructure.database.session import engine, Base
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyCategoryRepository
from app.infrastructure.database.session import AsyncSessionLocal

from app.presentation.api.v1.auth import router as auth_router
from app.presentation.api.v1.categories import router as categories_router
from app.presentation.api.v1.bookings import router as bookings_router
from app.presentation.api.v1.technicians import router as technicians_router
from app.presentation.api.v1.messages import router as messages_router
from app.presentation.api.v1.payments import router as payments_router
from app.presentation.api.v1.reviews import router as reviews_router
from app.presentation.api.v1.subscriptions import router as subscriptions_router
from app.presentation.api.v1.websockets import router as websockets_router
from app.presentation.api.v1.admin import router as admin_router
from app.presentation.api.v1.quotes import router as quotes_router
from app.presentation.api.v1.wallet import router as wallet_router



import os
import firebase_admin
from firebase_admin import credentials

# ---------------------------------------------------------------------------
# Initialize Firebase Admin SDK
# ---------------------------------------------------------------------------
try:
    if not firebase_admin._apps:
        # Assuming the JSON file is at the root of the backend directory
        cred_path = os.path.join(os.getcwd(), "firebase-credentials.json")
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        else:
            print("WARNING: firebase-credentials.json not found!")
except Exception as e:
    print(f"Error initializing Firebase Admin: {e}")


# ---------------------------------------------------------------------------
# Rate limiter
# ---------------------------------------------------------------------------
limiter = Limiter(key_func=get_remote_address)


# ---------------------------------------------------------------------------
# Lifespan: startup / shutdown (replaces deprecated @app.on_event)
# ---------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    # ---- STARTUP ----
    # Create DB tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Seed system data only (categories — no passwords, no demo users)
    async with AsyncSessionLocal() as session:
        cat_repo = SQLAlchemyCategoryRepository(session)
        await cat_repo.seed_defaults()

    import asyncio
    from app.application.tasks import expire_stale_bookings_loop
    task = asyncio.create_task(expire_stale_bookings_loop())

    yield
    # ---- SHUTDOWN ---- (nothing to clean up for now)
    task.cancel()


# ---------------------------------------------------------------------------
# App instance
# ---------------------------------------------------------------------------
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    docs_url="/docs" if settings.ENVIRONMENT == "development" else None,
    redoc_url="/redoc" if settings.ENVIRONMENT == "development" else None,
    lifespan=lifespan,
)

# Attach rate limiter
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ---------------------------------------------------------------------------
# CORS — allow all local and remote web origins with credentials
# ---------------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^https?://.*",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)


# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------
@app.get("/")
async def root():
    return {
        "app": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "status": "online",
        "environment": settings.ENVIRONMENT,
        "docs": "/docs" if settings.ENVIRONMENT == "development" else "disabled",
    }


# ---------------------------------------------------------------------------
# API V1 Routers
# ---------------------------------------------------------------------------
app.include_router(auth_router, prefix=settings.API_V1_STR)
app.include_router(categories_router, prefix=settings.API_V1_STR)
app.include_router(bookings_router, prefix=settings.API_V1_STR)
app.include_router(technicians_router, prefix=settings.API_V1_STR)
app.include_router(messages_router, prefix=settings.API_V1_STR)
app.include_router(payments_router, prefix=settings.API_V1_STR)
app.include_router(reviews_router, prefix=settings.API_V1_STR)
app.include_router(subscriptions_router, prefix=settings.API_V1_STR)
app.include_router(admin_router, prefix=settings.API_V1_STR)
app.include_router(quotes_router, prefix=settings.API_V1_STR)
app.include_router(wallet_router, prefix=settings.API_V1_STR)

app.include_router(websockets_router)  # WebSocket routes have no /api/v1 prefix

# ---------------------------------------------------------------------------
# Static Uploads File Serving
# ---------------------------------------------------------------------------
import os
from fastapi.staticfiles import StaticFiles

uploads_dir = os.path.join(os.getcwd(), "uploads")
os.makedirs(uploads_dir, exist_ok=True)
app.mount("/static/uploads", StaticFiles(directory=uploads_dir), name="uploads")

