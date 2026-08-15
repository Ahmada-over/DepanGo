import json
from typing import Dict, Set
from fastapi import WebSocket

class ConnectionManager:
    def __init__(self):
        # Map booking_id -> Set[WebSocket]
        self.active_booking_connections: Dict[str, Set[WebSocket]] = {}
        # Map user_id -> WebSocket (for individual notifications e.g. technician offer alerts)
        self.user_connections: Dict[str, WebSocket] = {}
        # Map category_id -> Set[WebSocket] (for real-time area map)
        self.area_connections: Dict[str, Set[WebSocket]] = {}

    async def connect_user(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        # Close any existing connection for this user gracefully before overwriting
        if user_id in self.user_connections:
            try:
                await self.user_connections[user_id].close(code=1000)
            except Exception:
                pass
        self.user_connections[user_id] = websocket

    def disconnect_user(self, user_id: str):
        if user_id in self.user_connections:
            del self.user_connections[user_id]

    async def connect_booking(self, booking_id: str, websocket: WebSocket):
        if booking_id not in self.active_booking_connections:
            self.active_booking_connections[booking_id] = set()
        self.active_booking_connections[booking_id].add(websocket)

    def disconnect_booking(self, booking_id: str, websocket: WebSocket):
        if booking_id in self.active_booking_connections:
            self.active_booking_connections[booking_id].discard(websocket)
            if not self.active_booking_connections[booking_id]:
                del self.active_booking_connections[booking_id]

    async def send_personal_message(self, user_id: str, message: dict):
        if user_id in self.user_connections:
            ws = self.user_connections[user_id]
            try:
                await ws.send_json(message)
            except Exception:
                self.disconnect_user(user_id)

    async def broadcast_to_booking(self, booking_id: str, message: dict):
        if booking_id in self.active_booking_connections:
            dead_sockets = set()
            for ws in self.active_booking_connections[booking_id]:
                try:
                    await ws.send_json(message)
                except Exception:
                    dead_sockets.add(ws)
            for ws in dead_sockets:
                self.active_booking_connections[booking_id].discard(ws)

    async def connect_area(self, category_id: str, websocket: WebSocket):
        await websocket.accept()
        if category_id not in self.area_connections:
            self.area_connections[category_id] = set()
        self.area_connections[category_id].add(websocket)

    def disconnect_area(self, category_id: str, websocket: WebSocket):
        if category_id in self.area_connections:
            self.area_connections[category_id].discard(websocket)
            if not self.area_connections[category_id]:
                del self.area_connections[category_id]

    async def broadcast_to_area(self, category_id: str, message: dict):
        if category_id in self.area_connections:
            dead_sockets = set()
            for ws in self.area_connections[category_id]:
                try:
                    await ws.send_json(message)
                except Exception:
                    dead_sockets.add(ws)
            for ws in dead_sockets:
                self.area_connections[category_id].discard(ws)

ws_manager = ConnectionManager()
