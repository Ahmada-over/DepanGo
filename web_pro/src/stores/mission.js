import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useAuthStore } from './auth'
import { API_BASE } from '@/config'

export const useMissionStore = defineStore('mission', () => {
  const activeOffer = ref(null)
  const activeMission = ref(null)
  const countdown = ref(90)
  let timerInterval = null

  // Loading states for buttons
  const acceptLoading = ref(false)
  const statusLoading = ref(false)
  const locationLoading = ref(false)
  const refreshLoading = ref(false)

  // Real Database Interventions Data List
  const interventions = ref([])
  const techRating = ref(5.0)
  const techCategories = ref(['cat_plumbing', 'cat_electrical', 'cat_hvac'])
  const techTransportMode = ref('moto')
  const activeSubscription = ref(null)

  async function fetchSubscription(userId) {
    try {
      const authStore = useAuthStore()
      const response = await fetch(`${API_BASE}/subscriptions/me`, {
        headers: { 'Authorization': `Bearer ${authStore.token}` }
      })
      if (response.ok) {
        const data = await response.json()
        activeSubscription.value = data
      }
    } catch (err) {
      console.warn('Fetch Subscription Error:', err)
    }
  }

  async function subscribe(planName) {
    try {
      const authStore = useAuthStore()
      const response = await fetch(`${API_BASE}/subscriptions/`, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authStore.token}`
        },
        body: JSON.stringify({ plan_name: planName })
      })
      if (response.ok) {
        const data = await response.json()
        activeSubscription.value = data
        return true
      }
    } catch (err) {
      console.warn('Subscribe Error:', err)
    }
    return false
  }

  async function fetchInterventions(userId) {
    refreshLoading.value = true
    try {
      const authStore = useAuthStore()
      const response = await fetch(`${API_BASE}/bookings/user/${userId}?role=technician&_ts=${Date.now()}`, {
        headers: { 'Authorization': `Bearer ${authStore.token}` }
      })
      if (response.ok) {
        const data = await response.json()
        interventions.value = data.map(b => ({
          id: b.id,
          client_name: b.client_name || 'Client Inconnu',
          category: b.category_id === 'cat_plumbing' ? 'Plomberie' : (b.category_id === 'cat_hvac' ? 'Froid / Climatisation' : 'Électricité'),
          description: b.description,
          address: b.address_text,
          status: b.status,
          status_label: b.status === 'completed' ? 'Terminée' : (b.status === 'in_progress' ? 'En cours' : (b.status === 'on_site' ? 'Sur Place' : 'Nouvelle Demande')),
          color: b.status === 'completed' ? 'success' : (b.status === 'in_progress' ? 'info' : (b.status === 'on_site' ? 'warning' : 'primary')),
          date: new Date(b.created_at).toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' }),
          payment_type: 'Direct technicien (Sur devis)',
          rating: 5
        }))

        // Auto detect active mission (matched or in_progress or on_site)
        const active = data.find(b => ['matched', 'in_progress', 'on_site'].includes(b.status))
        if (active) {
          activeMission.value = {
            id: active.id,
            client_name: active.client_name || 'Client Inconnu',
            description: active.description,
            address: active.address_text,
            status: active.status,
            category_id: active.category_id,
            color: active.status === 'on_site' ? 'warning' : (active.status === 'in_progress' ? 'info' : 'primary'),
            status_label: active.status === 'on_site' ? 'Sur Place' : (active.status === 'in_progress' ? 'En cours d\'intervention' : 'Assignée / En route')
          }
        }

        // Offers are now strictly managed by WebSockets (MATCH_OFFER event)
      }
    } catch (err) {
      console.warn('Fetch Interventions Error:', err)
    } finally {
      refreshLoading.value = false
    }
  }

  async function fetchTechnicianProfile(userId) {
    try {
      const authStore = useAuthStore()
      const response = await fetch(`${API_BASE}/technicians/me?user_id=${userId}`, {
        headers: { 'Authorization': `Bearer ${authStore.token}` }
      })
      if (response.ok) {
        const data = await response.json()
        techRating.value = data.average_rating || 5.0
        if (data.category_ids && data.category_ids.length > 0) {
          techCategories.value = data.category_ids
        }
        if (data.transport_mode) {
          techTransportMode.value = data.transport_mode
        }
      }
    } catch (err) {
      console.warn('Fetch Profile Error:', err)
    }
  }

// Global Audio instance to help bypass some browser restrictions
const notificationAudio = new Audio('/sounds/notification.mp3')
notificationAudio.volume = 1.0

  function receiveOffer(offerData) {
    try {
      // Force reload to play again if already played
      notificationAudio.currentTime = 0
      notificationAudio.play().catch(e => console.warn('Audio play failed. Browser autoplay policy might require you to click anywhere on the page first:', e))
    } catch(e) {}

    activeOffer.value = offerData
    countdown.value = offerData.timeout_seconds || 90
    if (timerInterval) clearInterval(timerInterval)
    
    timerInterval = setInterval(() => {
      if (countdown.value > 0) {
        countdown.value--
      } else {
        rejectOffer()
      }
    }, 1000)
  }

  async function acceptOffer() {
    if (!activeOffer.value) return
    acceptLoading.value = true
    if (timerInterval) clearInterval(timerInterval)
    
    const bookingId = activeOffer.value.booking_id || ('INT-' + Math.floor(Math.random() * 9000 + 1000))
    
    try {
      const authStore = useAuthStore()
      const techId = authStore.user?.id
      const response = await fetch(`${API_BASE}/bookings/${bookingId}/status`, {
        method: 'PATCH',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authStore.token}`
        },
        body: JSON.stringify({ status: 'matched', technician_id: techId })
      })

      if (response.ok) {
        activeMission.value = {
          ...activeOffer.value,
          id: bookingId,
          status: 'matched',
          status_label: 'Assignée / En route',
          color: 'primary',
          eta: '15 mins'
        }
        activeOffer.value = null
      } else {
        console.warn('Failed to accept offer:', await response.text())
      }
    } catch (e) {
      console.warn('API accept error:', e)
    } finally {
      acceptLoading.value = false
      await fetchInterventions()
    }
  }

  async function acceptManualMission(bookingId) {
    if (!bookingId) return
    acceptLoading.value = true
    try {
      const authStore = useAuthStore()
      const techId = authStore.user?.id
      const response = await fetch(`${API_BASE}/bookings/${bookingId}/status`, {
        method: 'PATCH',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authStore.token}`
        },
        body: JSON.stringify({ status: 'matched', technician_id: techId })
      })

      if (response.ok) {
        const data = await response.json()
        activeMission.value = {
          ...activeMission.value,
          id: bookingId,
          status: 'matched',
          status_label: 'Assignée / En route',
          color: 'primary',
          eta: '15 mins'
        }
      }
    } catch (e) {
      console.warn('API accept error:', e)
    } finally {
      acceptLoading.value = false
      await fetchInterventions()
    }
  }

  async function rejectOffer() {
    if (timerInterval) clearInterval(timerInterval)
    if (activeOffer.value) {
      const bookingId = activeOffer.value.booking_id
      try {
        const authStore = useAuthStore()
        await fetch(`${API_BASE}/bookings/${bookingId}/decline`, {
          method: 'POST',
          headers: { 
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${authStore.token}`
          }
        })
      } catch (e) {
        console.warn('API reject error:', e)
      }
    }
    activeOffer.value = null
  }

  async function updateMissionStatus(nextStatus, cancellationReason = null) {
    if (!activeMission.value) return
    statusLoading.value = true
    
    const statusMap = {
      matched: { label: 'Assignée', color: 'primary' },
      in_progress: { label: 'En cours d\'intervention', color: 'info' },
      on_site: { label: 'Sur Place', color: 'warning' },
      completed: { label: 'Terminée & Clôturée', color: 'success' },
      cancelled: { label: 'Annulée', color: 'error' }
    }

    try {
      const authStore = useAuthStore()
      const payload = { status: nextStatus, technician_id: authStore.user?.id }
      if (cancellationReason) {
        payload.cancellation_reason = cancellationReason
      }
      
      await fetch(`${API_BASE}/bookings/${activeMission.value.id}/status`, {
        method: 'PATCH',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authStore.token}`
        },
        body: JSON.stringify(payload)
      })
    } catch (e) {
      console.warn('API status error:', e)
    } finally {
      activeMission.value.status = nextStatus
      activeMission.value.status_label = statusMap[nextStatus]?.label || nextStatus
      activeMission.value.color = statusMap[nextStatus]?.color || 'primary'

      if (nextStatus === 'completed') {
        activeMission.value = null
      }

      statusLoading.value = false
      await fetchInterventions()
    }
  }

  return {
    activeOffer,
    activeMission,
    countdown,
    interventions,
    techRating,
    techCategories,
    techTransportMode,
    acceptLoading,
    statusLoading,
    locationLoading,
    refreshLoading,
    fetchInterventions,
    fetchTechnicianProfile,
    fetchSubscription,
    subscribe,
    receiveOffer,
    acceptOffer,
    acceptManualMission,
    rejectOffer,
    updateMissionStatus
  }
})
