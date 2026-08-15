import os
from urllib.parse import quote_plus
from typing import Optional, List
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str = "depanGo API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"

    # Environment: development | production
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")

    # Database — no hardcoded passwords
    DATABASE_URL: Optional[str] = os.getenv("DATABASE_URL", None)
    POSTGRES_USER: str = os.getenv("POSTGRES_USER", "mirahtec")
    POSTGRES_PASSWORD: str = os.getenv("POSTGRES_PASSWORD", "")
    POSTGRES_SERVER: str = os.getenv("POSTGRES_SERVER", "localhost")
    POSTGRES_PORT: str = os.getenv("POSTGRES_PORT", "5432")
    POSTGRES_DB: str = os.getenv("POSTGRES_DB", "techconnect")

    @property
    def ASYNC_DATABASE_URL(self) -> str:
        if self.DATABASE_URL:
            return self.DATABASE_URL
        if not self.POSTGRES_PASSWORD:
            raise ValueError("POSTGRES_PASSWORD must be set via environment variable.")
        user = quote_plus(self.POSTGRES_USER)
        password = quote_plus(self.POSTGRES_PASSWORD)
        return f"postgresql+asyncpg://{user}:{password}@{self.POSTGRES_SERVER}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"

    @property
    def SYNC_DATABASE_URL(self) -> str:
        if self.DATABASE_URL:
            return self.DATABASE_URL.replace("+asyncpg", "").replace("+aiosqlite", "")
        user = quote_plus(self.POSTGRES_USER)
        password = quote_plus(self.POSTGRES_PASSWORD)
        return f"postgresql://{user}:{password}@{self.POSTGRES_SERVER}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"

    # JWT Security — SECRET_KEY must be set via environment variable in production
    SECRET_KEY: str = os.getenv("SECRET_KEY", "dev-only-secret-key-CHANGE-IN-PRODUCTION")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

    @property
    def check_secret_key(self) -> None:
        if self.ENVIRONMENT == "production" and self.SECRET_KEY == "dev-only-secret-key-CHANGE-IN-PRODUCTION":
            raise ValueError("SECRET_KEY must be configured via environment variable in production.")

    # CORS — comma-separated list of allowed origins
    ALLOWED_ORIGINS: List[str] = [
        o.strip() for o in
        os.getenv("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:3002,http://localhost:8080,http://localhost:5173").split(",")
        if o.strip()
    ]

    # Matching config — configurable via environment
    MATCHING_RESPONSE_WINDOW_SECONDS: int = int(os.getenv("MATCHING_TIMEOUT_SECONDS", "90"))
    MAX_RADIUS_KM: float = float(os.getenv("MAX_RADIUS_KM", "25.0"))
    INITIAL_SEARCH_RADIUS_KM: float = float(os.getenv("INITIAL_RADIUS_KM", "10.0"))
    EXPANDED_SEARCH_RADIUS_KM: float = float(os.getenv("MAX_RADIUS_KM", "25.0"))

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )

settings = Settings()
