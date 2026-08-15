import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useNotificationStore = defineStore('notification', () => {
  const notifications = ref([])
  const latestToast = ref(null)

  const unreadCount = computed(() => notifications.value.filter(n => !n.read).length)

  function init() {
    // Called on login — add the welcome notification once
    if (!notifications.value.find(n => n.id === 'notif_welcome')) {
      notifications.value = [{
        id: 'notif_welcome',
        title: 'Bienvenue sur TechConnect Pro !',
        message: 'Votre compte technicien est actif. Vous recevrez des notifications en temps réel lors des demandes clientes.',
        time: 'À l\'instant',
        type: 'system',
        icon: 'mdi-shield-check',
        color: 'success',
        read: false
      }]
    }
  }

  function clearAll() {
    // Called on logout — wipe all notifications for this session
    notifications.value = []
    latestToast.value = null
  }

  function addNotification({ title, message, type = 'info', icon = 'mdi-bell', color = 'primary' }) {
    const newNotif = {
      id: 'notif_' + Date.now(),
      title,
      message,
      time: new Date().toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }),
      type,
      icon,
      color,
      read: false
    }
    notifications.value.unshift(newNotif)
    latestToast.value = newNotif

    // Trigger browser native Notification if allowed
    if ('Notification' in window && Notification.permission === 'granted') {
      try {
        new Notification(title, { body: message, icon: '/favicon.ico' })
      } catch (e) {
        console.warn('Browser notification error:', e)
      }
    }
  }

  function markAllAsRead() {
    notifications.value.forEach(n => n.read = true)
  }

  function clearNotification(id) {
    notifications.value = notifications.value.filter(n => n.id !== id)
  }

  function requestNotificationPermission() {
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission()
    }
  }

  return {
    notifications,
    latestToast,
    unreadCount,
    init,
    clearAll,
    addNotification,
    markAllAsRead,
    clearNotification,
    requestNotificationPermission
  }
})

