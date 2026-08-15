from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from app.infrastructure.websockets.connection_manager import ws_manager
from app.core.security import decode_token
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.repositories.sqlalchemy_repositories import SQLAlchemyBookingRepository

router = APIRouter(tags=["WebSockets"])

@router.websocket("/ws/bookings/{booking_id}")
async def websocket_booking_endpoint(websocket: WebSocket, booking_id: str, token: str = Query(None)):
    await websocket.accept()
    user_id = decode_token(token) if token else None
    if not user_id:
        await websocket.close(code=4001, reason="Unauthorized")
        return

    # Verify user is allowed to access this booking (client or technician)
    async with AsyncSessionLocal() as session:
        booking_repo = SQLAlchemyBookingRepository(session)
        booking = await booking_repo.get_by_id(booking_id)
        if not booking or user_id not in (booking.client_id, booking.technician_id):
            await websocket.close(code=4003, reason="Forbidden")
            return

    await ws_manager.connect_booking(booking_id, websocket)
    try:
        while True:
            data = await websocket.receive_json()
            data["booking_id"] = booking_id
            await ws_manager.broadcast_to_booking(booking_id, data)
    except WebSocketDisconnect:
        ws_manager.disconnect_booking(booking_id, websocket)


@router.websocket("/ws/users/{user_id}")
async def websocket_user_endpoint(websocket: WebSocket, user_id: str, token: str = Query(None)):
    token_user_id = decode_token(token) if token else None
    if not token_user_id or token_user_id != user_id:
        await websocket.close(code=4001, reason="Unauthorized")
        return

    await ws_manager.connect_user(user_id, websocket)
    try:
        while True:
            data = await websocket.receive_json()
            await ws_manager.send_personal_message(user_id, {"type": "PONG", "received": data})
    except WebSocketDisconnect:
        ws_manager.disconnect_user(user_id)

@router.websocket("/ws/area/{category_id}")
async def websocket_area_endpoint(websocket: WebSocket, category_id: str, token: str = Query(None)):
    # The map area endpoint is public, no strict auth required for viewing.

    await ws_manager.connect_area(category_id, websocket)
    try:
        while True:
            # We don't expect messages from clients on this broadcast channel,
            # but we need to receive to keep connection alive and detect disconnects.
            await websocket.receive_text()
    except WebSocketDisconnect:
        ws_manager.disconnect_area(category_id, websocket)
