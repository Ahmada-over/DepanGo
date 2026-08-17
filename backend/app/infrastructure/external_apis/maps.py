import httpx
import logging
from typing import List, Dict, Optional
from app.core.config import settings

logger = logging.getLogger("depango")

class GoogleMapsEtaService:
    """
    Service to fetch real-time ETA (Estimated Time of Arrival) using Google Maps Distance Matrix API.
    """
    def __init__(self):
        self.api_key = settings.GOOGLE_MAPS_API_KEY
        self.base_url = "https://maps.googleapis.com/maps/api/distancematrix/json"

    async def get_etas(self, client_lat: float, client_lon: float, tech_locations: List[tuple]) -> Dict[tuple, Optional[int]]:
        """
        Fetches ETAs from a single origin to multiple destinations.
        Returns a dictionary mapping (lat, lon) -> ETA in seconds.
        If an ETA cannot be calculated, the value will be None.
        """
        result = {loc: None for loc in tech_locations}
        
        if not self.api_key:
            logger.warning("[MAPS API] GOOGLE_MAPS_API_KEY is not set. Falling back to None for ETAs.")
            return result
            
        if not tech_locations:
            return result

        origins = f"{client_lat},{client_lon}"
        destinations = "|".join([f"{lat},{lon}" for lat, lon in tech_locations])

        params = {
            "origins": origins,
            "destinations": destinations,
            "key": self.api_key,
            "mode": "driving",
            "departure_time": "now" # Required to get duration_in_traffic
        }

        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(self.base_url, params=params, timeout=10.0)
                response.raise_for_status()
                data = response.json()
                
                if data.get("status") != "OK":
                    logger.error(f"[MAPS API] Error from Google Maps: {data.get('status')} - {data.get('error_message')}")
                    return result
                    
                rows = data.get("rows", [])
                if not rows:
                    return result
                    
                elements = rows[0].get("elements", [])
                
                # The elements array corresponds 1:1 with the destinations passed
                for i, loc in enumerate(tech_locations):
                    if i < len(elements):
                        element = elements[i]
                        status = element.get("status")
                        if status == "OK":
                            # Use duration_in_traffic if available, otherwise duration
                            duration_info = element.get("duration_in_traffic") or element.get("duration")
                            if duration_info and "value" in duration_info:
                                result[loc] = duration_info["value"]
                        else:
                            logger.warning(f"[MAPS API] Destination {loc} returned status {status}")

        except Exception as e:
            logger.error(f"[MAPS API] Failed to fetch ETAs: {e}", exc_info=True)
            
        return result
