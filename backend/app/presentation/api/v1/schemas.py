from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

# Auth Schemas
class RegisterRequest(BaseModel):
    name: str
    phone: str
    password: str
    email: Optional[str] = None
    role: str = "client" # client | technician
    category_ids: Optional[List[str]] = None
    transport_mode: Optional[str] = "moto"

class LoginRequest(BaseModel):
    password: str
    email: Optional[str] = None
    phone: Optional[str] = None

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    user: dict

# Category Schemas
class CategoryResponse(BaseModel):
    id: str
    name: str
    description: str
    icon_name: str
    base_price: Optional[float] = None

# Booking Schemas
class BookingCreateRequest(BaseModel):
    category_id: str
    description: str
    latitude: float
    longitude: float
    address_text: str
    photo_url: Optional[str] = None
    preferred_technician_id: Optional[str] = None

class BookingStatusUpdateRequest(BaseModel):
    status: str # matched | in_progress | completed | cancelled
    technician_id: Optional[str] = None
    cancellation_reason: Optional[str] = None

class BookingResponse(BaseModel):
    id: str
    client_id: str
    client_name: Optional[str] = None
    category_id: str
    description: str
    photo_url: Optional[str] = None
    status: str
    latitude: float
    longitude: float
    address_text: str
    technician_id: Optional[str] = None
    technician_name: Optional[str] = None
    scheduled_eta: Optional[str] = None
    cancellation_reason: Optional[str] = None
    created_at: datetime

# Location & Availability Schemas
class AvailabilityUpdateRequest(BaseModel):
    status: str # online | offline

class LocationUpdateRequest(BaseModel):
    latitude: float
    longitude: float
    eta: Optional[str] = None

class TransportUpdateRequest(BaseModel):
    transport_mode: str # moto | voiture

# Message Schemas
class MessageCreateRequest(BaseModel):
    content: str

class MessageResponse(BaseModel):
    id: str
    booking_id: str
    sender_id: str
    sender_name: Optional[str] = None
    content: str
    sent_at: datetime

# Review & Payment Schemas
class ReviewCreateRequest(BaseModel):
    rating: int
    comment: Optional[str] = None

class PaymentCreateRequest(BaseModel):
    amount: float = 0.0
    method: str = "direct_cash" # direct_cash | mobile_money_direct | sur_devis

class SubscriptionResponse(BaseModel):
    id: str
    technician_id: str
    plan_name: str
    status: str
    start_date: datetime
    end_date: Optional[datetime] = None

class SubscriptionCreateRequest(BaseModel):
    plan_name: str


class FirebaseLoginRequest(BaseModel):
    id_token: str
    name: Optional[str] = None
    role: Optional[str] = "technician"


# --- Quote Schemas ---
class QuoteItemBase(BaseModel):
    description: str
    category: str # labor | material | travel
    quantity: int = 1
    unit_price: float
    total_price: float

class QuoteItemCreate(QuoteItemBase):
    pass

class QuoteItemResponse(QuoteItemBase):
    id: str
    quote_id: str

    model_config = {"from_attributes": True}

class QuoteBase(BaseModel):
    booking_id: str
    quote_type: str # remote_estimate | on_site_quote
    total_labor: float = 0.0
    total_materials: float = 0.0
    total_travel: float = 0.0
    grand_total: float = 0.0
    estimated_duration: Optional[str] = None
    notes: Optional[str] = None

class QuoteCreate(QuoteBase):
    items: List[QuoteItemCreate]

class QuoteResponse(QuoteBase):
    id: str
    technician_id: str
    client_id: str
    status: str
    created_at: datetime
    updated_at: datetime
    items: List[QuoteItemResponse] = []

    model_config = {"from_attributes": True}

class QuoteStatusUpdate(BaseModel):
    status: str # pending_client_approval | accepted | rejected

# --- Wallet Schemas ---
class WalletResponse(BaseModel):
    id: str
    technician_id: str
    balance: float

class WalletTopUpRequest(BaseModel):
    amount: float

class WalletRefundRequest(BaseModel):
    booking_id: str

class WalletTransactionResponse(BaseModel):
    id: str
    amount: float
    type: str
    reason: str
    booking_id: Optional[str] = None
    created_at: Optional[str] = None
