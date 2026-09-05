from enum import Enum
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, List

class UserRole(str, Enum):
    CLIENT = "client"
    TECHNICIAN = "technician"
    ADMIN = "admin"

class AvailabilityStatus(str, Enum):
    ONLINE = "online"
    OFFLINE = "offline"

class BookingStatus(str, Enum):
    PENDING = "pending"
    MATCHED = "matched"
    ACCEPTED = "accepted"
    IN_PROGRESS = "in_progress"
    ON_SITE = "on_site"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    NO_TECHNICIAN = "no_technician_found"

class PaymentStatus(str, Enum):
    PENDING = "pending"
    PAID_DIRECT = "paid_direct"
    CANCELLED = "cancelled"

class PaymentMethod(str, Enum):
    DIRECT_CASH = "direct_cash"
    MOBILE_MONEY_DIRECT = "mobile_money_direct"
    SUR_DEVIS = "sur_devis"

@dataclass
class UserDomain:
    id: str
    name: str
    phone: str
    email: str
    role: UserRole
    password_hash: str
    created_at: datetime = field(default_factory=datetime.utcnow)

@dataclass
class ServiceCategoryDomain:
    id: str
    name: str
    description: str
    icon_name: str
    base_price: Optional[float] = None

@dataclass
class TechnicianProfileDomain:
    id: str
    user_id: str
    category_ids: List[str]
    latitude: float
    longitude: float
    availability_status: AvailabilityStatus
    average_rating: float = 5.0
    verified: bool = False
    location_updated_at: Optional[datetime] = None
    user_name: Optional[str] = None
    user_phone: Optional[str] = None
    transport_mode: str = "moto"

@dataclass
class BookingDomain:
    id: str
    client_id: str
    category_id: str
    description: str
    photo_url: Optional[str]
    status: BookingStatus
    latitude: float
    longitude: float
    address_text: str
    client_name: Optional[str] = None
    technician_id: Optional[str] = None
    scheduled_eta: Optional[str] = None
    cancellation_reason: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.utcnow)
    version: int = 1

@dataclass
class MessageDomain:
    id: str
    booking_id: str
    sender_id: str
    content: str
    sent_at: datetime = field(default_factory=datetime.utcnow)
    sender_name: Optional[str] = None

@dataclass
class SubscriptionDomain:
    id: str
    technician_id: str
    plan_name: str
    status: str
    start_date: datetime
    end_date: Optional[datetime] = None

@dataclass
class ReviewDomain:
    id: str
    booking_id: str
    reviewer_id: str
    target_id: str
    rating: int
    comment: str
    created_at: datetime = field(default_factory=datetime.utcnow)

@dataclass
class PaymentDomain:
    id: str
    booking_id: str
    amount: float
    status: PaymentStatus
    method: PaymentMethod
    created_at: datetime = field(default_factory=datetime.utcnow)

class TransactionType(str, Enum):
    CREDIT = "credit"
    DEBIT = "debit"

class TransactionReason(str, Enum):
    WELCOME_BONUS = "welcome_bonus"
    LEAD_PURCHASE = "lead_purchase"
    REFUND = "refund"
    TOP_UP = "top_up"

@dataclass
class WalletDomain:
    id: str
    technician_id: str
    balance: float = 0.0
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)

@dataclass
class WalletTransactionDomain:
    id: str
    wallet_id: str
    amount: float
    transaction_type: TransactionType
    reason: TransactionReason
    booking_id: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.utcnow)
