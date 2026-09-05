import asyncio
import httpx
import uuid
import random

API_BASE = "http://localhost:8001/api/v1"

async def main():
    async with httpx.AsyncClient() as client:
        print("1. Création Client et Technicien...")
        r = str(uuid.uuid4())[:6]
        phone_client = f"77{random.randint(1000000, 9999999)}"
        phone_tech = f"76{random.randint(1000000, 9999999)}"
        
        client_data = {"name": f"Client_{r}", "phone": phone_client, "password": "pass", "email": f"client_{r}@test.com", "role": "client"}
        tech_data = {"name": f"Tech_{r}", "phone": phone_tech, "password": "pass", "email": f"tech_{r}@test.com", "role": "technician"}
        
        res = await client.post(f"{API_BASE}/auth/register", json=client_data)
        client_token = res.json()["access_token"]
        
        res = await client.post(f"{API_BASE}/auth/register", json=tech_data)
        tech_token = res.json()["access_token"]
        tech_id = res.json()["user"]["id"]

        print("2. Création d'une catégorie et d'une mission...")
        cat_res = await client.get(f"{API_BASE}/categories")
        cat_id = cat_res.json()[0]["id"]

        book_data = {
            "category_id": cat_id,
            "description": "Fuite d'eau",
            "latitude": 14.6,
            "longitude": -17.4,
            "address_text": "Dakar"
        }
        res = await client.post(f"{API_BASE}/bookings", json=book_data, headers={"Authorization": f"Bearer {client_token}"})
        if res.status_code != 200:
            print("Erreur création mission:", res.text)
            return
        booking = res.json()
        booking_id = booking["id"]
        print(f"Mission créée: {booking_id}")

        print("3. Match de la mission (Technicien accepte)...")
        res = await client.patch(f"{API_BASE}/bookings/{booking_id}/status", json={"status": "in_progress", "technician_id": tech_id}, headers={"Authorization": f"Bearer {tech_token}"})
        if res.status_code != 200:
            print("Erreur update mission:", res.text)
            return

        print("4. Le Technicien crée un Devis sur place...")
        quote_data = {
            "booking_id": booking_id,
            "quote_type": "on_site_quote",
            "total_labor": 10000.0,
            "total_materials": 5000.0,
            "total_travel": 2000.0,
            "grand_total": 17000.0,
            "estimated_duration": "2 heures",
            "notes": "Remplacement tuyauterie",
            "items": [
                {"description": "Main d'oeuvre Plomberie", "category": "labor", "quantity": 1, "unit_price": 10000.0, "total_price": 10000.0},
                {"description": "Tuyau PVC", "category": "material", "quantity": 2, "unit_price": 2500.0, "total_price": 5000.0},
                {"description": "Frais déplacement", "category": "travel", "quantity": 1, "unit_price": 2000.0, "total_price": 2000.0}
            ]
        }
        res = await client.post(f"{API_BASE}/quotes", json=quote_data, headers={"Authorization": f"Bearer {tech_token}"})
        quote = res.json()
        if res.status_code != 200:
            print("Erreur création devis:", res.text)
            return
            
        quote_id = quote["id"]
        print(f"Devis créé avec succès par le Tech! ID: {quote_id} - Grand Total: {quote['grand_total']} FCFA")

        print("5. Le Technicien tente d'accepter lui-même le devis (Doit échouer!)...")
        res = await client.patch(f"{API_BASE}/quotes/{quote_id}/status", json={"status": "accepted"}, headers={"Authorization": f"Bearer {tech_token}"})
        print(f"Statut HTTP (Attendu: 403): {res.status_code} - {res.text}")

        print("6. Le Client accepte le devis...")
        res = await client.patch(f"{API_BASE}/quotes/{quote_id}/status", json={"status": "accepted"}, headers={"Authorization": f"Bearer {client_token}"})
        print(f"Statut HTTP (Attendu: 200): {res.status_code} - Nouveau statut: {res.json().get('status')}")

asyncio.run(main())
