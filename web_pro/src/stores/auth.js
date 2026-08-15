import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useNotificationStore } from '@/stores/notification'
import { API_BASE } from '@/config'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('tech_token') || '')
  const user = ref(JSON.parse(localStorage.getItem('tech_user') || 'null'))
  
  const isAuthenticated = computed(() => !!token.value && token.value !== '')
  const isOnline = ref(true)
  let locationInterval = null

  function startLocationTracking() {
    if (locationInterval) return
    locationInterval = setInterval(() => {
      if (navigator.geolocation && user.value && isOnline.value) {
        navigator.geolocation.getCurrentPosition(
          async (position) => {
            try {
              let lat = position.coords.latitude
              let lng = position.coords.longitude
              // Override San Francisco (Mac default) to Dakar for testing
              if (lat > 37.7 && lat < 37.8 && lng < -122.3 && lng > -122.5) {
                lat = 14.6928
                lng = -17.4467
              }
              await fetch(`${API_BASE}/technicians/me/location?user_id=${user.value.id}`, {
                method: 'POST',
                headers: { 
                  'Content-Type': 'application/json',
                  'Authorization': `Bearer ${token.value}`
                },
                body: JSON.stringify({
                  latitude: lat,
                  longitude: lng
                })
              })
            } catch (err) {
              console.warn('Location sync warning:', err)
            }
          },
          (error) => {
            console.warn('Geolocation error:', error)
          }
        )
      }
    }, 10000) // Envoi toutes les 10 secondes
  }

  function stopLocationTracking() {
    if (locationInterval) {
      clearInterval(locationInterval)
      locationInterval = null
    }
  }

  // Démarrer automatiquement si connecté
  if (token.value && isOnline.value) {
    startLocationTracking()
  }

  async function registerTechnician(formData) {
    try {
      const response = await fetch(`${API_BASE}/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: formData.name,
          email: formData.email,
          phone: formData.phone,
          password: formData.password,
          role: 'technician',
          category_ids: formData.category_ids || ['cat_plumbing']
        })
      })
      
      const data = await response.json()
      if (!response.ok) {
        throw new Error(data.detail || 'Erreur lors de l\'inscription')
      }

      token.value = data.access_token
      user.value = data.user
      localStorage.setItem('tech_token', data.access_token)
      localStorage.setItem('tech_user', JSON.stringify(data.user))
      return data
    } catch (err) {
      console.error('API register error:', err)
      throw err
    }
  }

  async function login(email, password) {
    try {
      const response = await fetch(`${API_BASE}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      })

      const data = await response.json()
      if (!response.ok) {
        throw new Error(data.detail || 'Erreur d\'authentification')
      }

      token.value = data.access_token
      user.value = data.user
      localStorage.setItem('tech_token', data.access_token)
      localStorage.setItem('tech_user', JSON.stringify(data.user))
      useNotificationStore().init()
      if (isOnline.value) startLocationTracking()
      return data
    } catch (err) {
      console.error('API login error:', err)
      throw err
    }
  }

  function logout() {
    useNotificationStore().clearAll()
    token.value = ''
    user.value = null
    localStorage.removeItem('tech_token')
    localStorage.removeItem('tech_user')
    stopLocationTracking()
  }

  async function toggleAvailability() {
    isOnline.value = !isOnline.value
    if (!user.value) return
    try {
      await fetch(`${API_BASE}/technicians/me/availability?user_id=${user.value.id}`, {
        method: 'PATCH',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token.value}`
        },
        body: JSON.stringify({ status: isOnline.value ? 'online' : 'offline' })
      })
      if (isOnline.value) {
        startLocationTracking()
      } else {
        stopLocationTracking()
      }
    } catch (err) {
      console.warn('API sync warning:', err)
    }
  }

  async function updateUserProfile(updatedData) {
    if (user.value) {
      user.value = { ...user.value, ...updatedData }
      localStorage.setItem('tech_user', JSON.stringify(user.value))
    }
    try {
      await fetch(`${API_BASE}/technicians/me/profile?user_id=${user.value?.id || 'user_tech_demo'}`, {
        method: 'PATCH',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token.value}`
        },
        body: JSON.stringify(updatedData)
      })
    } catch (e) {
      console.warn('Profile update sync warning:', e)
    }
  }

  return { token, user, isAuthenticated, isOnline, registerTechnician, login, logout, toggleAvailability, updateUserProfile }
})
