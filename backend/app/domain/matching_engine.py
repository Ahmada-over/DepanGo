import math
from typing import List, Optional
from app.domain.models import TechnicianProfileDomain

def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance between two coordinates in kilometers."""
    R = 6371.0 # Earth radius in km
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

class MatchingEngine:
    """
    Domain service handling technician matching logic.
    1. Filter candidates by category and online status
    2. Sort candidates by ETA (ascending) then average rating (descending)
    3. Return ordered list of candidates to offer the mission to sequentially
    """
    @staticmethod
    def filter_and_rank_technicians(
        candidates: List[TechnicianProfileDomain],
        client_lat: float,
        client_lon: float,
        category_id: str,
        max_radius_km: float = 15.0,
        eta_dict: Optional[dict[tuple, Optional[int]]] = None
    ) -> List[TechnicianProfileDomain]:
        valid_candidates = []
        for tech in candidates:
            if category_id != "cat_express" and category_id not in tech.category_ids:
                continue
            if tech.availability_status != "online":
                continue
            
            dist = haversine_distance(client_lat, client_lon, tech.latitude, tech.longitude)
            if dist <= max_radius_km:
                # Get ETA if available, otherwise fallback to a large number (so they rank last among those without ETA)
                eta = float('inf')
                if eta_dict:
                    loc = (tech.latitude, tech.longitude)
                    tech_eta = eta_dict.get(loc)
                    if tech_eta is not None:
                        eta = tech_eta
                
                valid_candidates.append((eta, tech.average_rating, dist, tech))
        
        # Sort by ETA asc, rating desc, distance asc
        valid_candidates.sort(key=lambda item: (item[0], -item[1], item[2]))
        return [item[3] for item in valid_candidates]
