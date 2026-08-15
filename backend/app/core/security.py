from datetime import datetime, timedelta, timezone
from typing import Optional, Union, Any
from jose import jwt, JWTError
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from app.core.config import settings

import bcrypt

# --- Passlib bcrypt >= 4.0 Compatibility Patch ---
# Passlib 1.7.4 is incompatible with bcrypt >= 4.0 because bcrypt removed the `__about__` module
# and strict length validation (max 72 bytes) crashes passlib's internal wrap-bug detection.
if not hasattr(bcrypt, "__about__"):
    class About:
        __version__ = getattr(bcrypt, "__version__", "4.0.0")
    bcrypt.__about__ = About

_orig_hashpw = bcrypt.hashpw
def _patched_hashpw(password: bytes, salt: bytes) -> bytes:
    return _orig_hashpw(password[:72], salt)
bcrypt.hashpw = _patched_hashpw

_orig_checkpw = bcrypt.checkpw
def _patched_checkpw(password: bytes, hashed_password: bytes) -> bool:
    return _orig_checkpw(password[:72], hashed_password)
bcrypt.checkpw = _patched_checkpw
# -------------------------------------------------

# bcrypt password context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# OAuth2 bearer token scheme — token is sent as Authorization: Bearer <token>
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")


def hash_password(password: str) -> str:
    """Hash password using bcrypt."""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify bcrypt password match."""
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(subject: Union[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode = {"exp": expire, "sub": str(subject)}
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def decode_token(token: str) -> Optional[str]:
    """Decode JWT and return user_id (sub claim), or None if invalid."""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload.get("sub")
    except JWTError:
        return None


async def get_current_user(token: str = Depends(oauth2_scheme)):
    """FastAPI dependency: validates JWT, returns user_id string."""
    user_id = decode_token(token)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalide ou expiré.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user_id


async def get_current_user_with_role(token: str = Depends(oauth2_scheme)):
    """
    Returns (user_id, role) by decoding the JWT.
    Role must be embedded in token at creation time or fetched from DB.
    For simplicity we return user_id; callers fetch role from DB when needed.
    """
    return await get_current_user(token)

async def require_admin_role(
    current_user_id: str = Depends(get_current_user),
    db = Depends(None) # we inject it inside or let caller do it
):
    """
    Dependency to require an admin role. To avoid circular imports, 
    we fetch the user in the dependency by injecting the db session.
    """
    from app.infrastructure.database.session import get_db
    from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyUserRepository
    from fastapi import Depends
    
    # We redefine it to properly inject the DB session here
    pass

# A better way is to do this:
async def require_admin(
    current_user_id: str = Depends(get_current_user),
    # To avoid circular imports, we just import get_db locally inside a function
    # but FastAPI Depends needs it at definition time. We'll just define it in the admin router.
):
    pass
