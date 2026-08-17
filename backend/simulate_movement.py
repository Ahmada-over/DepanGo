"""
Script de simulation de déplacement en direct pour TechConnect Dakar.
Ce script déplace virtuellement un technicien vers le client pas à pas
en émettant les coordonnées GPS au backend FastAPI via l'API & WebSocket.
"""

import sys
import time
import math
import requests

API_BASE = "http://localhost:8001/api/v1"

def simulate(booking_id: str, tech_id: str = None, total_steps: int = 20, delay_sec: float = 1.5):
    # 1. Fetch booking details
    print(f"📡 Récupération du dossier : {booking_id}...")
    res = requests.get(f"{API_BASE}/bookings/{booking_id}")
    if res.status_code != 200:
        print(f"❌ Impossible de trouver le dossier {booking_id} (Code {res.status_code})")
        return

    booking = res.json()
    dest_lat = booking.get("latitude", 14.6937)
    dest_lng = booking.get("longitude", -17.4441)
    assigned_tech = tech_id or booking.get("technician_id")
    client_name = booking.get("client_name") or "Client"

    print(f"🎯 Destination ({client_name}) : Lat {dest_lat}, Lng {dest_lng}")

    # 2. Starting point ~2km away in Dakar
    start_lat = dest_lat - 0.018
    start_lng = dest_lng - 0.014

    print(f"🛵 Démarrage de la simulation de trajet ({total_steps} étapes, {delay_sec}s d'intervalle)...")

    for step in range(1, total_steps + 1):
        t = step / total_steps
        current_lat = start_lat + (dest_lat - start_lat) * t + math.sin(t * math.pi) * 0.0012
        current_lng = start_lng + (dest_lng - start_lng) * t + math.cos(t * math.pi) * 0.0008

        remaining_min = max(0, round((1 - t) * 15))
        eta_str = "Sur place" if remaining_min == 0 else f"{remaining_min} min"
        progress = round(t * 100)

        # Emit location update
        try:
            # We can broadcast directly to booking
            payload = {
                "latitude": current_lat,
                "longitude": current_lng,
                "eta": eta_str
            }
            url = f"{API_BASE}/technicians/me/location?booking_id={booking_id}"
            headers = {"Authorization": "Bearer test_token", "Content-Type": "application/json"}
            # Let's send
            requests.post(url, json=payload, headers=headers, timeout=3)
            print(f"  [{progress:3d}%] 📍 Lat: {current_lat:.5f}, Lng: {current_lng:.5f} | ETA: {eta_str}")
        except Exception as e:
            print(f"  [{progress:3d}%] ⚠️ Avertissement d'envoi: {e}")

        time.sleep(delay_sec)

    print("🎉 Arrivée à destination ! Le technicien est sur place.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python simulate_movement.py <booking_id>")
        sys.exit(1)
    simulate(sys.argv[1])
