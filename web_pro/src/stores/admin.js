import { defineStore } from 'pinia'
import { ref } from 'vue'
import { useAuthStore } from './auth'
import { API_BASE } from '@/config'

export const useAdminStore = defineStore('admin', () => {
  const statsOverview = ref(null)
  const bookings = ref([])
  const technicians = ref([])
  const loading = ref(false)

  const authStore = useAuthStore()

  async function fetchOverview() {
    loading.value = true
    try {
      const res = await fetch(`${API_BASE}/admin/stats/overview`, {
        headers: { 'Authorization': `Bearer ${authStore.token}` }
      })
      if (res.ok) {
        statsOverview.value = await res.json()
      }
    } catch (err) {
      console.error('Erreur fetch overview:', err)
    } finally {
      loading.value = false
    }
  }

  async function fetchBookings() {
    loading.value = true
    try {
      const res = await fetch(`${API_BASE}/admin/bookings`, {
        headers: { 'Authorization': `Bearer ${authStore.token}` }
      })
      if (res.ok) {
        bookings.value = await res.json()
      }
    } catch (err) {
      console.error('Erreur fetch bookings:', err)
    } finally {
      loading.value = false
    }
  }

  async function fetchTechnicians() {
    loading.value = true
    try {
      const res = await fetch(`${API_BASE}/admin/technicians`, {
        headers: { 'Authorization': `Bearer ${authStore.token}` }
      })
      if (res.ok) {
        technicians.value = await res.json()
      }
    } catch (err) {
      console.error('Erreur fetch technicians:', err)
    } finally {
      loading.value = false
    }
  }

  async function verifyTechnician(userId) {
    try {
      const res = await fetch(`${API_BASE}/admin/technicians/${userId}/verify`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${authStore.token}` }
      })
      if (res.ok) {
        await fetchTechnicians()
      }
    } catch (err) {
      console.error('Erreur verify technician:', err)
    }
  }

  async function manualAssign(bookingId, techId) {
    try {
      const res = await fetch(`${API_BASE}/bookings/${bookingId}/status`, {
        method: 'PATCH',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authStore.token}` 
        },
        body: JSON.stringify({ status: 'matched', technician_id: techId })
      })
      if (res.ok) {
        await fetchBookings()
        return true
      }
    } catch (err) {
      console.error('Erreur manual assign:', err)
    }
    return false
  }

  return {
    statsOverview,
    bookings,
    technicians,
    loading,
    fetchOverview,
    fetchBookings,
    fetchTechnicians,
    verifyTechnician,
    manualAssign
  }
})
