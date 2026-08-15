import { defineStore } from 'pinia'
import { ref } from 'vue'
import { API_BASE, WS_BASE } from '@/config'

export const useChatStore = defineStore('chat', () => {
  const messages = ref([])
  const socket = ref(null)

  function connectBookingChat(bookingId) {
    if (socket.value) socket.value.close()
    
    socket.value = new WebSocket(`${WS_BASE}/bookings/${bookingId}`)
    
    socket.value.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data)
        if (data.type === 'NEW_MESSAGE') {
          messages.value.push({
            id: data.id,
            sender_id: data.sender_id,
            sender_name: data.sender_name,
            content: data.content,
            sent_at: data.sent_at
          })
        }
      } catch (err) {
        console.error('WS Parse Error:', err)
      }
    }
  }

  function sendMessage(bookingId, senderId, content) {
    if (socket.value && socket.value.readyState === WebSocket.OPEN) {
      socket.value.send(JSON.stringify({
        type: 'NEW_MESSAGE',
        sender_id: senderId,
        sender_name: 'Technicien Ousmane',
        content: content
      }))
    }
  }

  async function sendLocationUpdate(bookingId, lat, lon) {
    try {
      await fetch(`${API_BASE}/technicians/me/location?booking_id=${bookingId}&user_id=user_tech_demo`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ latitude: lat, longitude: lon })
      })
    } catch (e) {
      console.warn('Location API error:', e)
    }
  }

  return { messages, connectBookingChat, sendMessage, sendLocationUpdate }
})
