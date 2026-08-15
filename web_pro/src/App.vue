<template>
  <v-app class="bg-background">
    
    <!-- Pro Left Navigation Sidebar (Only displayed when authenticated) -->
    <v-navigation-drawer
      v-if="authStore.isAuthenticated"
      v-model="drawer"
      permanent
      elevation="4"
      color="surface"
      width="260"
      class="border-r"
    >
      <!-- Brand Header -->
      <div class="pa-4 d-flex align-center ga-3 border-b">
        <v-avatar color="primary" size="36" class="font-weight-black text-slate-950 rounded-lg">
          <v-icon icon="mdi-shield-account-outline" size="20"></v-icon>
        </v-avatar>
        <div>
          <div class="text-subtitle-1 font-weight-black text-white leading-tight">TechConnect Pro</div>
          <div class="text-caption text-grey">Plateforme Technicien & Service</div>
        </div>
      </div>

      <!-- User Identity Card (Clickable to go to Profile if technician) -->
      <component :is="authStore.user?.role === 'technician' ? 'router-link' : 'div'" to="/profile" class="text-decoration-none">
        <div class="pa-3 mx-2 my-3 rounded-lg bg-surface-variant border hover:border-primary transition-all">
          <div class="d-flex align-center ga-3">
            <v-avatar color="primary" size="34" class="font-weight-bold text-slate-950 text-caption">
              {{ userInitials }}
            </v-avatar>
            <div class="overflow-hidden">
              <div class="text-caption font-weight-bold text-white text-truncate">{{ authStore.user?.name || 'Utilisateur' }}</div>
              <div v-if="authStore.user?.role === 'technician'" class="text-caption text-success font-weight-medium">
                <v-icon icon="mdi-circle" size="8" class="me-1"></v-icon>
                {{ authStore.isOnline ? 'En Ligne (Disponible)' : 'Hors Ligne' }}
              </div>
              <div v-else class="text-caption text-primary font-weight-medium">
                <v-icon icon="mdi-shield-crown" size="12" class="me-1"></v-icon>Administrateur
              </div>
            </div>
          </div>
        </div>
      </component>

      <!-- Navigation Links -->
      <v-list density="compact" nav class="px-2">
        <!-- TECHNICIAN ONLY MENUS -->
        <template v-if="authStore.user?.role === 'technician'">
          <v-list-subheader class="text-uppercase text-caption font-weight-bold text-grey">GESTION D'INTERVENTIONS</v-list-subheader>
        
        <v-list-item
          to="/"
          exact
          value="dashboard"
          color="primary"
          rounded="lg"
          class="mb-1"
        >
          <template #prepend>
            <v-icon icon="mdi-view-dashboard-outline" class="me-3" size="20"></v-icon>
          </template>
          <v-list-item-title class="font-weight-bold text-caption">Tableau de Bord Operations</v-list-item-title>
        </v-list-item>

        <v-list-item
          to="/mission"
          value="mission"
          color="primary"
          rounded="lg"
          class="mb-1"
        >
          <template #prepend>
            <v-icon icon="mdi-transit-connection-variant" class="me-3" size="20"></v-icon>
          </template>
          <v-list-item-title class="font-weight-bold text-caption">Centre de Dispatch</v-list-item-title>
          <template #append>
            <v-badge v-if="missionStore.activeMission" color="primary" content="1" inline></v-badge>
          </template>
        </v-list-item>

        <v-list-item
          to="/history"
          value="history"
          color="primary"
          rounded="lg"
          class="mb-1"
        >
          <template #prepend>
            <v-icon icon="mdi-file-document-outline" class="me-3" size="20"></v-icon>
          </template>
          <v-list-item-title class="font-weight-bold text-caption">Historique & Archives</v-list-item-title>
        </v-list-item>
        </template>

        <!-- ADMIN ONLY MENUS -->

        <v-list-item
          v-if="authStore.user?.role === 'admin'"
          to="/admin"
          value="admin"
          color="primary"
          rounded="lg"
          class="mb-1"
        >
          <template #prepend>
            <v-icon icon="mdi-shield-crown-outline" class="me-3" size="20"></v-icon>
          </template>
          <v-list-item-title class="font-weight-bold text-caption">Dashboard Administrateur</v-list-item-title>
        </v-list-item>

        <template v-if="authStore.user?.role === 'technician'">
        <v-list-subheader class="text-uppercase text-caption font-weight-bold text-grey mt-4">MON COMPTE PRO</v-list-subheader>

        <v-list-item
          to="/profile"
          value="profile"
          color="primary"
          rounded="lg"
          class="mb-1"
        >
          <template #prepend>
            <v-icon icon="mdi-account-cog-outline" class="me-3" size="20"></v-icon>
          </template>
          <v-list-item-title class="font-weight-bold text-caption">Mon Profil & Spécialités</v-list-item-title>
        </v-list-item>
        </template>
      </v-list>

      <template #append>
        <div v-if="authStore.user?.role === 'technician'" class="pa-3 border-t">
          <v-switch
            v-model="authStore.isOnline"
            color="primary"
            density="compact"
            hide-details
            :label="authStore.isOnline ? 'Statut : EN LIGNE' : 'Statut : HORS LIGNE'"
            @change="authStore.toggleAvailability"
          ></v-switch>
        </div>
      </template>
    </v-navigation-drawer>

    <!-- Top Header Bar (Only displayed when authenticated) -->
    <v-app-bar v-if="authStore.isAuthenticated" flat border color="surface" height="56" class="px-3">
      <v-btn icon="mdi-menu" variant="text" @click="drawer = !drawer" class="d-lg-none me-2"></v-btn>

      <!-- Global Search Input -->
      <v-text-field
        placeholder="Rechercher une intervention, N° dossier, nom client..."
        prepend-inner-icon="mdi-magnify"
        density="compact"
        variant="outlined"
        hide-details
        color="primary"
        class="max-w-400 d-none d-sm-flex rounded-lg"
      ></v-text-field>

      <v-spacer></v-spacer>

      <!-- Quick Action Buttons & Dynamic Notification Menu -->
      <div class="d-flex align-center ga-3">
        <v-chip to="/profile" color="primary" variant="flat" size="small" class="font-weight-bold cursor-pointer">
          <v-icon start icon="mdi-shield-check" size="x-small"></v-icon> Compte Certifié
        </v-chip>

        <!-- Notification Bell Dropdown -->
        <v-menu location="bottom end" :close-on-content-click="false">
          <template #activator="{ props }">
            <v-btn v-bind="props" icon variant="text" size="small">
              <v-badge :content="notifStore.unreadCount" :model-value="notifStore.unreadCount > 0" color="error">
                <v-icon icon="mdi-bell-outline" size="20"></v-icon>
              </v-badge>
            </v-btn>
          </template>
          <v-card width="360" class="bg-surface rounded-lg border elevation-4 pa-3">
            <div class="d-flex align-center justify-space-between pb-2 border-b mb-2">
              <span class="text-subtitle-2 font-weight-bold text-white">Notifications Pro</span>
              <v-btn variant="text" color="primary" size="x-small" class="text-none font-weight-bold" @click="notifStore.markAllAsRead">
                Tout marquer comme lu
              </v-btn>
            </div>
            <div v-if="notifStore.notifications.length === 0" class="text-center py-6 text-grey text-caption">
              Aucune notification pour le moment.
            </div>
            <div class="overflow-y-auto" style="max-height: 320px;">
              <div
                v-for="notif in notifStore.notifications"
                :key="notif.id"
                class="pa-3 rounded-lg mb-2 border transition-all"
                :class="notif.read ? 'bg-surface opacity-75' : 'bg-surface-variant border-primary'"
              >
                <div class="d-flex align-center justify-space-between mb-1">
                  <div class="d-flex align-center ga-2">
                    <v-icon :icon="notif.icon" :color="notif.color" size="16"></v-icon>
                    <span class="text-caption font-weight-bold text-white">{{ notif.title }}</span>
                  </div>
                  <span class="text-caption text-grey opacity-75">{{ notif.time }}</span>
                </div>
                <div class="text-caption text-grey-lighten-2">{{ notif.message }}</div>
              </div>
            </div>
          </v-card>
        </v-menu>

        <v-divider vertical inset class="mx-1"></v-divider>

        <v-menu location="bottom end">
          <template #activator="{ props }">
            <v-btn v-bind="props" variant="text" class="text-none">
              <v-avatar color="primary" size="30" class="me-2 text-slate-950 font-weight-bold text-caption">
                {{ userInitials }}
              </v-avatar>
              <span class="font-weight-bold text-caption d-none d-sm-inline">{{ authStore.user?.name || 'Technicien' }}</span>
              <v-icon icon="mdi-chevron-down" size="small" class="ms-1"></v-icon>
            </v-btn>
          </template>
          <v-list density="compact" class="bg-surface rounded-lg border" width="190">
            <v-list-item to="/profile" title="Mon Profil Pro" prepend-icon="mdi-account-outline"></v-list-item>
            <v-list-item to="/profile" title="Mes Spécialités" prepend-icon="mdi-wrench-outline"></v-list-item>
            <v-divider class="my-1"></v-divider>
            <v-list-item title="Déconnexion" prepend-icon="mdi-logout" color="error" @click="handleLogout"></v-list-item>
          </v-list>
        </v-menu>
      </div>
    </v-app-bar>

    <!-- Main Content Area with Smooth Fluid Page Transitions -->
    <v-main class="bg-background">
      <router-view v-slot="{ Component }">
        <transition name="page-fade" mode="out-in">
          <component :is="Component" />
        </transition>
      </router-view>
    </v-main>

    <!-- Global Glassmorphic Notification Toast Snackbar -->
    <v-snackbar
      v-model="showToast"
      location="top right"
      timeout="4500"
      color="transparent"
      elevation="0"
      class="pa-0"
    >
      <div
        class="pa-4 rounded-xl d-flex align-center ga-3 border border-primary transition-all shadow-2xl"
        style="background: rgba(15, 23, 42, 0.94); backdrop-filter: blur(16px); min-width: 320px;"
      >
        <v-avatar :color="toastData?.color || 'primary'" size="38" class="font-weight-bold">
          <v-icon :icon="toastData?.icon || 'mdi-bell-ring'" size="20" color="slate-950"></v-icon>
        </v-avatar>
        <div class="flex-grow-1">
          <div class="text-subtitle-2 font-weight-black text-white leading-tight">{{ toastData?.title }}</div>
          <div class="text-caption text-grey-lighten-2 line-clamp-2 mt-1">{{ toastData?.message }}</div>
        </div>
        <v-btn icon="mdi-close" variant="text" size="x-small" color="grey" @click="showToast = false"></v-btn>
      </div>
    </v-snackbar>

    <!-- Global Mission Offer Popup Dialog (With 90s Countdown) -->
    <MissionOfferModal v-if="authStore.isAuthenticated" />
  </v-app>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import MissionOfferModal from '@/components/MissionOfferModal.vue'
import { useAuthStore } from '@/stores/auth'
import { useMissionStore } from '@/stores/mission'
import { useNotificationStore } from '@/stores/notification'
import { WS_BASE } from '@/config'

const drawer = ref(true)
const router = useRouter()
const authStore = useAuthStore()
const missionStore = useMissionStore()
const notifStore = useNotificationStore()

const showToast = ref(false)
const toastData = ref(null)

watch(() => notifStore.latestToast, (newToast) => {
  if (newToast) {
    toastData.value = newToast
    showToast.value = true
  }
})

const userInitials = computed(() => {
  const name = authStore.user?.name || 'Tech'
  const parts = name.split(' ')
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase()
  }
  return name.slice(0, 2).toUpperCase()
})

function handleLogout() {
  authStore.logout()
  router.push('/login')
}

let wsReconnectDelay = 1 // seconds
let wsInstance = null
let wsIntentionalClose = false

function connectWs() {
  if (wsIntentionalClose) return
  const userId = authStore.user?.id
  const token = authStore.token
  if (!userId || !token) return

  try {
    wsInstance = new WebSocket(`${WS_BASE}/users/${userId}?token=${token}`)

      wsInstance.onopen = () => {
        wsReconnectDelay = 1 // reset on successful connection
      }

      const playNotificationSound = () => {
        const audio = new Audio('/notification.mp3')
        audio.play().catch(e => console.warn('Audio play failed:', e))
      }

      wsInstance.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data)
          let shouldPlaySound = false;
          
          if (data.type === 'MATCH_OFFER') {
            missionStore.receiveOffer(data)
            missionStore.fetchInterventions(userId)
            notifStore.addNotification({
              title: 'Nouvelle Mission 90s !',
              message: `Demande d'intervention à ${data.address || 'Dakar'}. Validez avant 90s.`,
              type: 'offer',
              icon: 'mdi-bell-ring',
              color: 'success'
            })
            shouldPlaySound = true;
          } else if (data.type === 'STATUS_UPDATE') {
            missionStore.fetchInterventions(userId)
            notifStore.addNotification({
              title: 'Mise à Jour Dossier',
              message: `Le statut du dossier a été mis à jour : ${data.status}`,
              type: 'status',
              icon: 'mdi-information-outline',
              color: 'info'
            })
            shouldPlaySound = true;
          } else if (data.type === 'NEW_MESSAGE') {
            notifStore.addNotification({
              title: `Message de ${data.sender_name || 'Client'}`,
              message: data.content,
              type: 'chat',
              icon: 'mdi-message-text-outline',
              color: 'primary'
            })
            shouldPlaySound = true;
          } else if (data.type === 'NO_TECHNICIAN') {
            notifStore.addNotification({
              title: 'Aucun technicien disponible',
              message: data.message || 'Aucun technicien qualifié disponible. Réessayez dans quelques instants.',
              type: 'warning',
              icon: 'mdi-account-off-outline',
              color: 'warning'
            })
            shouldPlaySound = true;
          }

          if (shouldPlaySound) {
            playNotificationSound();
          }
        } catch (e) {
          console.warn('[WS] Parse error:', e)
        }
      }

      wsInstance.onclose = () => {
        if (!wsIntentionalClose) {
          console.warn(`[WS] Disconnected. Reconnecting in ${wsReconnectDelay}s...`)
          setTimeout(() => {
            wsReconnectDelay = Math.min(wsReconnectDelay * 2, 30)
            connectWs()
          }, wsReconnectDelay * 1000)
        }
      }

      wsInstance.onerror = (err) => {
        console.warn('[WS] Error:', err)
        // onclose will fire after onerror, which handles reconnect
      }
    } catch (err) {
      console.warn('[WS] Init error:', err)
      setTimeout(() => {
        wsReconnectDelay = Math.min(wsReconnectDelay * 2, 30)
        connectWs()
      }, wsReconnectDelay * 1000)
    }
  }

onMounted(() => {
  if (!authStore.isAuthenticated) {
    router.push('/login')
  } else {
    notifStore.init()
    connectWs()
  }

  notifStore.requestNotificationPermission()
})

watch(() => authStore.isAuthenticated, (newVal) => {
  if (newVal) {
    notifStore.init()
    connectWs()
  } else {
    if (wsInstance) {
      wsIntentionalClose = true
      wsInstance.close()
    }
  }
})
</script>

<style>
.max-w-400 {
  max-width: 400px;
}
.cursor-pointer {
  cursor: pointer;
}
</style>
