from abc import ABC, abstractmethod
from typing import Optional, List
from app.domain.models import (
    UserDomain, TechnicianProfileDomain, ServiceCategoryDomain,
    BookingDomain, MessageDomain, ReviewDomain, PaymentDomain,
    SubscriptionDomain
)

class UserRepositoryPort(ABC):
    @abstractmethod
    async def create(self, user: UserDomain) -> UserDomain: pass
    
    @abstractmethod
    async def get_by_email(self, email: str) -> Optional[UserDomain]: pass

    @abstractmethod
    async def get_by_phone(self, phone: str) -> Optional[UserDomain]: pass

    @abstractmethod
    async def get_by_identifier(self, identifier: str) -> Optional[UserDomain]: pass
    
    @abstractmethod
    async def get_by_id(self, user_id: str) -> Optional[UserDomain]: pass

class SubscriptionRepositoryPort(ABC):
    @abstractmethod
    async def create(self, subscription: SubscriptionDomain) -> SubscriptionDomain: pass
    
    @abstractmethod
    async def get_active_by_technician(self, technician_id: str) -> Optional[SubscriptionDomain]: pass

class TechnicianRepositoryPort(ABC):
    @abstractmethod
    async def create_profile(self, profile: TechnicianProfileDomain) -> TechnicianProfileDomain: pass
    
    @abstractmethod
    async def get_by_user_id(self, user_id: str) -> Optional[TechnicianProfileDomain]: pass
    
    @abstractmethod
    async def update_availability(self, user_id: str, status: str) -> None: pass
    
    @abstractmethod
    async def update_location(self, user_id: str, lat: float, lon: float) -> None: pass
    
    @abstractmethod
    async def get_available_near(self, category_id: str, lat: float, lon: float, radius_km: float) -> List[TechnicianProfileDomain]: pass

    @abstractmethod
    async def update_rating(self, user_id: str, new_rating: float) -> None: pass

    @abstractmethod
    async def update_verification_status(self, user_id: str, verified: bool) -> None:
        pass

    @abstractmethod
    async def update_transport_mode(self, user_id: str, mode: str) -> None:
        pass

    @abstractmethod
    async def get_all(self) -> List[TechnicianProfileDomain]: pass

    @abstractmethod
    async def update_user_info(self, user_id: str, name: Optional[str] = None, email: Optional[str] = None, phone: Optional[str] = None) -> None: pass

    @abstractmethod
    async def update_categories(self, user_id: str, category_ids: List[str]) -> None: pass

    @abstractmethod
    async def get_all_registered(self) -> List[TechnicianProfileDomain]: pass

class CategoryRepositoryPort(ABC):
    @abstractmethod
    async def get_all(self) -> List[ServiceCategoryDomain]: pass
    
    @abstractmethod
    async def seed_defaults(self) -> None: pass

class BookingRepositoryPort(ABC):
    @abstractmethod
    async def create(self, booking: BookingDomain) -> BookingDomain: pass
    
    @abstractmethod
    async def get_by_id(self, booking_id: str) -> Optional[BookingDomain]: pass
    
    @abstractmethod
    async def update_status(self, booking_id: str, status: str, technician_id: Optional[str] = None, cancellation_reason: Optional[str] = None) -> BookingDomain: pass
    
    @abstractmethod
    async def get_by_user(self, user_id: str, role: str) -> List[BookingDomain]: pass

class MessageRepositoryPort(ABC):
    @abstractmethod
    async def create(self, message: MessageDomain) -> MessageDomain: pass
    
    @abstractmethod
    async def get_by_booking_id(self, booking_id: str) -> List[MessageDomain]: pass

class ReviewRepositoryPort(ABC):
    @abstractmethod
    async def create(self, review: ReviewDomain) -> ReviewDomain: pass

class PaymentRepositoryPort(ABC):
    @abstractmethod
    async def create(self, payment: PaymentDomain) -> PaymentDomain: pass
