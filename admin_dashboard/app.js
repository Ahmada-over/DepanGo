/**
 * DepanGo Pro — Admin Operations & Real-Time Monitoring Dashboard
 * Dakar Fleet Tracking & System Telemetry
 */

const CONFIG = {
  CLOUD_RUN_URL: 'https://backend-depango-346078879462.europe-west1.run.app',
  LOCAL_URL: 'http://127.0.0.1:8001',
  DEFAULT_ENV: 'cloud', // 'cloud' | 'local'
  DAKAR_CENTER: [14.6937, -17.4441],
};

// --- Application State ---
const state = {
  currentEnv: localStorage.getItem('depango_admin_env') || CONFIG.DEFAULT_ENV,
  token: localStorage.getItem('depango_admin_token') || '',
  adminUser: JSON.parse(localStorage.getItem('depango_admin_user') || 'null'),
  currentTab: 'overview',
  refreshInterval: 10000,
  timerId: null,
  
  // Data caches
  overview: null,
  fleet: [],
  missions: [],
  technicians: [],
  health: null,
  analytics: null,
  
  // Map instance & layers
  map: null,
  markersLayer: null,
  routesLayer: null,
  fleetFilter: 'all',
  
  // Chart instances
  trendChart: null,
  categoryChart: null,
};

// --- Base URL Getter ---
function getApiBase() {
  const host = state.currentEnv === 'local' ? CONFIG.LOCAL_URL : CONFIG.CLOUD_RUN_URL;
  return `${host}/api/v1`;
}

// --- HTTP Client ---
async function apiRequest(endpoint, options = {}) {
  const url = `${getApiBase()}${endpoint}`;
  const headers = {
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  };

  if (state.token) {
    headers['Authorization'] = `Bearer ${state.token}`;
  }

  try {
    const response = await fetch(url, { ...options, headers });
    
    if (response.status === 401 || response.status === 403) {
      // Prompt login if unauthorized
      openLoginModal();
      throw new Error('Session expirée ou non autorisée.');
    }

    if (!response.ok) {
      const err = await response.json().catch(() => ({ detail: 'Erreur réseau' }));
      throw new Error(err.detail || `Erreur ${response.status}`);
    }

    return await response.json();
  } catch (error) {
    console.error(`[API Error] ${endpoint}:`, error);
    throw error;
  }
}

// --- Toast Notifications ---
function showToast(message, type = 'info') {
  const container = document.getElementById('toastContainer');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  
  let icon = 'fa-info-circle';
  if (type === 'success') icon = 'fa-circle-check';
  if (type === 'error') icon = 'fa-triangle-exclamation';

  toast.innerHTML = `
    <i class="fa-solid ${icon}"></i>
    <span>${message}</span>
  `;

  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// --- Initialization ---
document.addEventListener('DOMContentLoaded', () => {
  setupNavigation();
  setupEnvironment();
  setupRefreshControls();
  setupMap();
  setupCharts();
  setupSearchAndFilters();
  setupModals();

  // Check auth or start data loop
  if (!state.token) {
    openLoginModal();
  } else {
    refreshAllData();
    startAutoRefresh();
  }
});

// --- Navigation Tabs ---
function setupNavigation() {
  const navItems = document.querySelectorAll('.nav-item');
  const titleMap = {
    overview: "Vue d'Ensemble & KPIs",
    radar: "Radar Flotte Live (Dakar)",
    missions: "Supervision des Interventions",
    technicians: "Gestion des Techniciens & KYC",
    monitoring: "Santé Système & Infrastructure",
  };

  navItems.forEach((item) => {
    item.addEventListener('click', () => {
      const tab = item.getAttribute('data-tab');
      state.currentTab = tab;

      navItems.forEach((i) => i.classList.remove('active'));
      item.classList.add('active');

      document.querySelectorAll('.tab-pane').forEach((pane) => pane.classList.remove('active'));
      const activePane = document.getElementById(`pane-${tab}`);
      if (activePane) activePane.classList.add('active');

      document.getElementById('pageTitle').textContent = titleMap[tab] || 'Supervision';

      if (tab === 'radar' && state.map) {
        setTimeout(() => state.map.invalidateSize(), 200);
      }
    });
  });
}

// --- Environment Toggle ---
function setupEnvironment() {
  const envTag = document.getElementById('currentEnvTag');
  const btnToggle = document.getElementById('btnToggleEnv');

  const updateDisplay = () => {
    envTag.textContent = state.currentEnv === 'local' ? 'LOCAL (8001)' : 'CLOUD RUN';
    envTag.style.background = state.currentEnv === 'local' ? 'rgba(245, 158, 11, 0.2)' : 'rgba(59, 130, 246, 0.2)';
    envTag.style.color = state.currentEnv === 'local' ? 'var(--accent-amber)' : 'var(--accent-blue)';
  };

  updateDisplay();

  btnToggle.addEventListener('click', () => {
    state.currentEnv = state.currentEnv === 'local' ? 'cloud' : 'local';
    localStorage.setItem('depango_admin_env', state.currentEnv);
    updateDisplay();
    showToast(`Bascule vers l'environnement ${state.currentEnv.toUpperCase()}`, 'info');
    refreshAllData();
  });
}

// --- Auto-Refresh Engine ---
function setupRefreshControls() {
  const select = document.getElementById('autoRefreshInterval');
  const btnManual = document.getElementById('btnManualRefresh');

  select.addEventListener('change', (e) => {
    state.refreshInterval = parseInt(e.target.value, 10);
    startAutoRefresh();
    showToast(state.refreshInterval > 0 ? `Actualisation auto : ${state.refreshInterval / 1000}s` : 'Actualisation auto désactivée', 'info');
  });

  btnManual.addEventListener('click', () => {
    btnManual.querySelector('i').classList.add('fa-spin');
    refreshAllData().finally(() => {
      setTimeout(() => btnManual.querySelector('i').classList.remove('fa-spin'), 600);
    });
  });
}

function startAutoRefresh() {
  if (state.timerId) clearInterval(state.timerId);
  if (state.refreshInterval > 0) {
    state.timerId = setInterval(() => {
      refreshAllData(true);
    }, state.refreshInterval);
  }
}

// --- Leaflet Supervision Map ---
function setupMap() {
  const mapElement = document.getElementById('supervisionMap');
  if (!mapElement) return;

  state.map = L.map('supervisionMap', {
    zoomControl: false,
    attributionControl: false,
  }).setView(CONFIG.DAKAR_CENTER, 13);

  L.control.zoom({ position: 'bottomright' }).addTo(state.map);

  // High contrast dark tile layer
  L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
    maxZoom: 19,
    subdomains: 'abcd',
  }).addTo(state.map);

  state.markersLayer = L.layerGroup().addTo(state.map);
  state.routesLayer = L.layerGroup().addTo(state.map);
}

// --- Custom Leaflet Marker Icons ---
function createCustomPin(iconClass, bgColor, borderColor = '#ffffff') {
  return L.divIcon({
    className: 'custom-leaflet-marker',
    html: `
      <div style="
        width: 38px;
        height: 38px;
        background: ${bgColor};
        border: 2.5px solid ${borderColor};
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        color: #ffffff;
        font-size: 16px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.5);
      ">
        <i class="${iconClass}"></i>
      </div>
    `,
    iconSize: [38, 38],
    iconAnchor: [19, 19],
    popupAnchor: [0, -20],
  });
}

// --- Chart.js Setups ---
function setupCharts() {
  const trendCtx = document.getElementById('trendChart')?.getContext('2d');
  const catCtx = document.getElementById('categoryChart')?.getContext('2d');

  if (trendCtx) {
    state.trendChart = new Chart(trendCtx, {
      type: 'bar',
      data: {
        labels: ['12/08', '13/08', '14/08', '15/08', '16/08', '17/08', '18/08'],
        datasets: [
          {
            label: 'Demandes totales',
            data: [0, 0, 0, 0, 0, 0, 0],
            backgroundColor: 'rgba(59, 130, 246, 0.4)',
            borderColor: '#3B82F6',
            borderWidth: 1.5,
            borderRadius: 6,
          },
          {
            label: 'Dépannages réussis',
            data: [0, 0, 0, 0, 0, 0, 0],
            backgroundColor: 'rgba(16, 185, 129, 0.7)',
            borderColor: '#10B981',
            borderWidth: 1.5,
            borderRadius: 6,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { labels: { color: '#9CA3AF', font: { family: 'Plus Jakarta Sans', size: 11 } } },
        },
        scales: {
          x: { grid: { color: '#1F2937' }, ticks: { color: '#9CA3AF' } },
          y: { grid: { color: '#1F2937' }, ticks: { color: '#9CA3AF', stepSize: 5 } },
        },
      },
    });
  }

  if (catCtx) {
    state.categoryChart = new Chart(catCtx, {
      type: 'doughnut',
      data: {
        labels: ['Plomberie', 'Électricité', 'Froid & Clim', 'Électroménager', 'Express'],
        datasets: [
          {
            data: [1, 1, 1, 1, 1],
            backgroundColor: ['#10B981', '#3B82F6', '#F59E0B', '#8B5CF6', '#EC4899'],
            borderColor: '#111827',
            borderWidth: 3,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: 'bottom', labels: { color: '#9CA3AF', font: { family: 'Plus Jakarta Sans', size: 11 } } },
        },
        cutout: '68%',
      },
    });
  }
}

// --- Master Data Refresh ---
async function refreshAllData(silent = false) {
  try {
    const [overview, health, fleet, missions, techs, analytics] = await Promise.all([
      apiRequest('/admin/stats/overview').catch(() => null),
      apiRequest('/admin/monitoring/health').catch(() => null),
      apiRequest('/admin/monitoring/fleet').catch(() => []),
      apiRequest('/admin/bookings').catch(() => []),
      apiRequest('/admin/technicians').catch(() => []),
      apiRequest('/admin/stats/analytics').catch(() => null),
    ]);

    if (overview) renderOverview(overview);
    if (health) renderHealth(health);
    if (fleet) renderFleet(fleet);
    if (missions) renderMissions(missions);
    if (techs) renderTechnicians(techs);
    if (analytics) renderAnalytics(analytics);

    // Update Top Counters
    if (missions) {
      const activeCount = missions.filter((m) => ['pending', 'matched', 'in_progress', 'on_site'].includes(m.status)).length;
      document.getElementById('sidebarLiveMissionsCount').textContent = activeCount;
      document.getElementById('sidebarTotalBookingsCount').textContent = missions.length;
    }
    if (techs) {
      document.getElementById('sidebarTotalTechsCount').textContent = techs.length;
    }
  } catch (error) {
    if (!silent) showToast(error.message || 'Erreur de chargement des données', 'error');
  }
}

// --- Render 1 : Overview ---
function renderOverview(data) {
  state.overview = data;
  document.getElementById('kpiOnlineTechs').textContent = data.online_technicians;
  document.getElementById('kpiTotalTechs').textContent = `Sur ${data.total_technicians} inscrits (${data.total_clients} clients)`;
  
  document.getElementById('kpiActiveMissions').textContent = data.active_missions;
  document.getElementById('kpiPendingMissions').textContent = `${data.pending_missions} en attente d'artisan`;

  document.getElementById('kpiTotalCompleted').textContent = data.total_completed;
  document.getElementById('kpiCompletedToday').textContent = `${data.completed_today} réalisés aujourd'hui`;

  document.getElementById('kpiEstimatedGmv').textContent = `${Number(data.estimated_gmv_cfa).toLocaleString()} CFA`;
  document.getElementById('kpiEstimatedCommission').textContent = `Commissions : ${Number(data.estimated_commission_cfa).toLocaleString()} CFA`;
}

// --- Render 2 : Analytics & Funnel ---
function renderAnalytics(data) {
  state.analytics = data;

  // Funnel
  if (data.matching_funnel) {
    document.getElementById('funnelTotalOffers').textContent = data.matching_funnel.total_offers_sent;
    document.getElementById('funnelAcceptedOffers').textContent = data.matching_funnel.accepted_offers;
    document.getElementById('funnelTimeoutOffers').textContent = data.matching_funnel.timeout_offers;
    document.getElementById('funnelConversionRate').textContent = `${data.matching_funnel.acceptance_rate_percent}%`;
  }

  // Trend Chart
  if (state.trendChart && data.daily_trends_7d) {
    state.trendChart.data.labels = data.daily_trends_7d.map((d) => d.date);
    state.trendChart.data.datasets[0].data = data.daily_trends_7d.map((d) => d.total_requests);
    state.trendChart.data.datasets[1].data = data.daily_trends_7d.map((d) => d.completed);
    state.trendChart.update();
  }

  // Category Chart
  if (state.categoryChart && data.category_distribution) {
    const labelsMap = {
      cat_plumbing: 'Plomberie',
      cat_hvac: 'Froid & Clim',
      cat_electrical: 'Électricité',
      cat_appliances: 'Électroménager',
      cat_express: 'Dépannage Express',
    };
    const keys = Object.keys(data.category_distribution);
    state.categoryChart.data.labels = keys.map((k) => labelsMap[k] || k);
    state.categoryChart.data.datasets[0].data = Object.values(data.category_distribution);
    state.categoryChart.update();
  }
}

// --- Render 3 : Fleet Radar Map ---
function renderFleet(fleet) {
  state.fleet = fleet;
  if (!state.markersLayer) return;

  state.markersLayer.clearLayers();
  const filtered = filterFleetData(fleet);

  // Update counter badges
  const onlineCount = fleet.filter((t) => t.availability_status === 'online').length;
  const busyCount = fleet.filter((t) => t.has_active_mission).length;
  document.getElementById('countFilterAll').textContent = fleet.length;
  document.getElementById('countFilterOnline').textContent = onlineCount;
  document.getElementById('countFilterBusy').textContent = busyCount;

  // Add markers
  filtered.forEach((tech) => {
    const lat = tech.latitude || 14.6937;
    const lng = tech.longitude || -17.4441;

    let iconClass = tech.transport_mode === 'voiture' ? 'fa-solid fa-car-side' : 'fa-solid fa-motorcycle';
    let bgColor = '#6B7280'; // Gray offline

    if (tech.has_active_mission) {
      bgColor = '#F59E0B'; // Amber in mission
    } else if (tech.availability_status === 'online') {
      bgColor = '#10B981'; // Emerald online
    }

    const pin = createCustomPin(iconClass, bgColor);
    const marker = L.marker([lat, lng], { icon: pin }).addTo(state.markersLayer);

    const popupHtml = `
      <div style="font-family: 'Plus Jakarta Sans', sans-serif; color: #111827; padding: 4px; min-width: 200px;">
        <div style="font-weight: 800; font-size: 14px; margin-bottom: 2px;">${tech.name}</div>
        <div style="font-size: 11px; color: #4B5563; margin-bottom: 8px;">
          ${tech.transport_mode === 'voiture' ? '🚗 Voiture' : '🛵 Moto'} • ${tech.phone}
        </div>
        <div style="display: flex; gap: 4px; margin-bottom: 8px;">
          <span style="font-size: 10px; font-weight: 700; padding: 2px 6px; border-radius: 4px; background: ${tech.availability_status === 'online' ? '#D1FAE5' : '#F3F4F6'}; color: ${tech.availability_status === 'online' ? '#047857' : '#374151'};">
            ${tech.availability_status === 'online' ? '🟢 EN LIGNE' : '⚪ HORS LIGNE'}
          </span>
          <span style="font-size: 10px; font-weight: 700; padding: 2px 6px; border-radius: 4px; background: ${tech.verified ? '#DBEAFE' : '#FEF3C7'}; color: ${tech.verified ? '#1E40AF' : '#92400E'};">
            ${tech.verified ? 'KYC VALIDÉ' : 'EN ATTENTE KYC'}
          </span>
        </div>
        <div style="font-size: 12px; font-weight: 700; color: #047857;">Note : ${tech.average_rating.toFixed(1)} ★</div>
      </div>
    `;
    marker.bindPopup(popupHtml);
  });

  // Render Fleet Sidebar List
  renderFleetSidebarList(filtered);
}

function filterFleetData(fleet) {
  const query = (document.getElementById('fleetSearchInput')?.value || '').toLowerCase();
  return fleet.filter((t) => {
    const matchesQuery = t.name.toLowerCase().includes(query) || t.phone.includes(query);
    if (!matchesQuery) return false;

    if (state.fleetFilter === 'online') return t.availability_status === 'online';
    if (state.fleetFilter === 'busy') return t.has_active_mission;
    return true;
  });
}

function renderFleetSidebarList(fleet) {
  const container = document.getElementById('fleetCardsList');
  if (!container) return;

  if (fleet.length === 0) {
    container.innerHTML = `<div style="text-align: center; color: var(--text-muted); padding: 24px; font-size: 12px;">Aucun artisan trouvé.</div>`;
    return;
  }

  container.innerHTML = fleet
    .map((t) => {
      const isOnline = t.availability_status === 'online';
      const isBusy = t.has_active_mission;
      const statusClass = isBusy ? 'busy' : isOnline ? 'online' : 'offline';
      const statusText = isBusy ? 'En Mission' : isOnline ? 'En Ligne' : 'Pause';
      const vehicleIcon = t.transport_mode === 'voiture' ? 'fa-car-side' : 'fa-motorcycle';

      return `
        <div class="fleet-item" onclick="focusOnTech(${t.latitude || 14.6937}, ${t.longitude || -17.4441})">
          <div class="fleet-item-icon" style="background: ${isOnline ? 'rgba(16, 185, 129, 0.15)' : 'rgba(107, 114, 128, 0.15)'}; color: ${isOnline ? 'var(--primary-light)' : 'var(--text-muted)'};">
            <i class="fa-solid ${vehicleIcon}"></i>
          </div>
          <div class="fleet-item-info">
            <div class="fleet-item-name">${t.name}</div>
            <div class="fleet-item-sub">${t.phone} • ${t.average_rating.toFixed(1)} ★</div>
          </div>
          <span class="status-badge ${statusClass}">${statusText}</span>
        </div>
      `;
    })
    .join('');
}

window.focusOnTech = (lat, lng) => {
  if (state.map) {
    state.map.flyTo([lat, lng], 16, { animate: true, duration: 1 });
  }
};

// --- Render 4 : Missions Table ---
function renderMissions(missions) {
  state.missions = missions;
  const tbody = document.getElementById('missionsTableBody');
  if (!tbody) return;

  const query = (document.getElementById('missionSearchInput')?.value || '').toLowerCase();
  const statusFilter = document.getElementById('missionStatusFilter')?.value || '';

  const filtered = missions.filter((m) => {
    const matchesQuery =
      m.client_name.toLowerCase().includes(query) ||
      m.address_text.toLowerCase().includes(query) ||
      (m.technician_name && m.technician_name.toLowerCase().includes(query));
    if (!matchesQuery) return false;
    if (statusFilter && m.status !== statusFilter) return false;
    return true;
  });

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="8" style="text-align: center; color: var(--text-muted); padding: 24px;">Aucune intervention trouvée.</td></tr>`;
    return;
  }

  tbody.innerHTML = filtered
    .map((m) => {
      const shortId = m.id.substring(0, 8);
      const isPending = m.status === 'pending';
      const statusBadge = getStatusBadge(m.status);

      return `
        <tr>
          <td style="font-family: var(--font-mono); font-weight: 700; color: var(--text-secondary);">#${shortId}</td>
          <td>
            <div style="font-weight: 700;">${m.client_name}</div>
            <div style="font-size: 11px; color: var(--text-muted);">${m.client_phone}</div>
          </td>
          <td>
            <span style="font-size: 11px; font-weight: 700; padding: 2px 8px; border-radius: var(--radius-sm); background: rgba(16, 185, 129, 0.15); color: var(--primary-light);">
              ${{ cat_plumbing: 'Plomberie', cat_hvac: 'Froid & Clim', cat_electrical: 'Électricité', cat_appliances: 'Électroménager', cat_express: 'Urgence Express' }[m.category_id] || m.category_id}
            </span>
          </td>
          <td style="max-width: 180px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
            ${m.address_text}
            ${m.photo_url ? `<a href="${m.photo_url.startsWith('http') ? m.photo_url : state.apiUrl.replace('/api/v1', '') + m.photo_url}" target="_blank" style="display: inline-block; margin-left: 6px; color: var(--accent-cyan);" title="Voir la photo de la panne"><i class="fa-solid fa-camera"></i></a>` : ''}
          </td>
          <td>
            ${
              m.technician_name
                ? `<div style="font-weight: 700; color: #fff;">${m.technician_name}</div><div style="font-size: 11px; color: var(--text-muted);">${m.technician_phone || ''}</div>`
                : `<span style="color: var(--accent-amber); font-weight: 600; font-size: 12px;">En recherche...</span>`
            }
          </td>
          <td>${statusBadge}</td>
          <td style="font-size: 12px; color: var(--text-muted);">
            ${m.created_at ? new Date(m.created_at).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }) : '--:--'}
          </td>
          <td>
            ${
              isPending
                ? `<button class="btn btn-primary btn-sm" onclick="openAssignModal('${m.id}', '${m.client_name}', '${m.category_id}')">
                    <i class="fa-solid fa-bolt"></i> Assigner
                   </button>`
                : `<span style="font-size: 11px; color: var(--text-muted);">Assigné</span>`
            }
          </td>
        </tr>
      `;
    })
    .join('');
}

function getStatusBadge(status) {
  const map = {
    pending: '<span class="status-badge busy">En attente</span>',
    matched: '<span class="status-badge" style="background: rgba(59, 130, 246, 0.2); color: var(--accent-blue); border: 1px solid var(--accent-blue);">Assigné</span>',
    in_progress: '<span class="status-badge online">En route</span>',
    on_site: '<span class="status-badge online">Sur place</span>',
    completed: '<span class="status-badge online">Terminé ✅</span>',
    cancelled: '<span class="status-badge" style="background: rgba(239, 68, 68, 0.2); color: var(--accent-red);">Annulé</span>',
    no_technician_found: '<span class="status-badge" style="background: rgba(239, 68, 68, 0.2); color: var(--accent-red);">Échec Matching</span>',
  };
  return map[status] || `<span class="status-badge offline">${status}</span>`;
}

// --- Render 5 : Technicians & KYC Table ---
function renderTechnicians(techs) {
  state.technicians = techs;
  const tbody = document.getElementById('techniciansTableBody');
  if (!tbody) return;

  const query = (document.getElementById('techSearchInput')?.value || '').toLowerCase();
  const kycFilter = document.getElementById('techFilterKyc')?.value || '';

  const filtered = techs.filter((t) => {
    const matchesQuery = t.name.toLowerCase().includes(query) || t.phone.includes(query);
    if (!matchesQuery) return false;
    if (kycFilter === 'verified' && !t.verified) return false;
    if (kycFilter === 'unverified' && t.verified) return false;
    return true;
  });

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="9" style="text-align: center; color: var(--text-muted); padding: 24px;">Aucun technicien trouvé.</td></tr>`;
    return;
  }

  tbody.innerHTML = filtered
    .map((t) => {
      const isOnline = t.availability_status === 'online';
      const vehicleIcon = t.transport_mode === 'voiture' ? '🚗 Voiture' : '🛵 Moto Express';
      const categories = (t.category_ids || []).map((c) => c.replace('cat_', '')).join(', ') || 'Général';

      return `
        <tr>
          <td>
            <div style="font-weight: 700; color: #fff;">${t.name}</div>
            <div style="font-size: 11px; color: var(--text-muted);">${t.email || 'Sans email'}</div>
          </td>
          <td style="font-family: var(--font-mono); font-weight: 600;">
            <a href="tel:${t.phone}" style="color: var(--primary-light); text-decoration: none;">${t.phone}</a>
          </td>
          <td>${vehicleIcon}</td>
          <td style="font-size: 12px; color: var(--text-secondary);">${categories}</td>
          <td>
            <button class="btn ${isOnline ? 'btn-primary' : 'btn-outline'} btn-sm" onclick="toggleAvailability('${t.user_id}', '${t.availability_status}')">
              ${isOnline ? '🟢 En Ligne' : '⏸️ En Pause'}
            </button>
          </td>
          <td style="font-weight: 700; color: var(--accent-amber);">${t.average_rating.toFixed(1)} ★</td>
          <td style="font-weight: 700;">${t.completed_missions}</td>
          <td>
            <span class="status-badge ${t.verified ? 'online' : 'busy'}">
              ${t.verified ? 'Vérifié ✅' : 'En attente ⏳'}
            </span>
          </td>
          <td>
            <button class="btn ${t.verified ? 'btn-danger' : 'btn-primary'} btn-sm" onclick="toggleKycVerification('${t.user_id}', ${t.verified})">
              ${t.verified ? 'Révoquer KYC' : 'Valider KYC'}
            </button>
          </td>
        </tr>
      `;
    })
    .join('');
}

// --- Toggle KYC & Availability ---
window.toggleKycVerification = async (userId, currentVerified) => {
  try {
    const res = await apiRequest(`/admin/technicians/${userId}/toggle-verify`, {
      method: 'POST',
      body: JSON.stringify({ verified: !currentVerified }),
    });
    showToast(res.message || 'Statut KYC mis à jour !', 'success');
    refreshAllData();
  } catch (e) {
    showToast(e.message || 'Erreur lors de la validation KYC', 'error');
  }
};

window.toggleAvailability = async (userId, currentStatus) => {
  const newStatus = currentStatus === 'online' ? 'offline' : 'online';
  try {
    const res = await apiRequest(`/admin/technicians/${userId}/toggle-availability`, {
      method: 'POST',
      body: JSON.stringify({ availability: newStatus }),
    });
    showToast(res.message || 'Disponibilité mise à jour', 'success');
    refreshAllData();
  } catch (e) {
    showToast(e.message || 'Erreur lors du changement de statut', 'error');
  }
};

// --- Render 6 : System Health & Monitoring ---
function renderHealth(health) {
  state.health = health;

  // DB Latency
  const latency = health.database?.latency_ms || 0;
  document.getElementById('monDbLatency').textContent = `${latency} ms`;
  const dbBar = document.getElementById('monDbBar');
  if (dbBar) {
    dbBar.style.width = `${Math.min(latency * 10, 100)}%`;
    dbBar.className = `progress-bar-fill ${latency > 50 ? 'danger' : latency > 20 ? 'warning' : ''}`;
  }

  // WebSockets
  if (health.websockets) {
    document.getElementById('monWsSockets').textContent = health.websockets.total_open_sockets;
    document.getElementById('monWsDetails').textContent = `${health.websockets.active_user_channels} users • ${health.websockets.active_booking_channels} bookings`;
  }

  // Uptime
  if (health.system) {
    document.getElementById('monUptimeFormatted').textContent = health.system.uptime_formatted || '--';
    document.getElementById('monDispatchEngine').textContent = `Moteur : ${health.system.dispatch_engine}`;
  }
}

// --- Modals & Actions ---
function setupModals() {
  // Manual Assign Modal
  document.getElementById('btnCancelAssign')?.addEventListener('click', () => {
    document.getElementById('manualAssignModal').classList.remove('active');
  });

  document.getElementById('btnConfirmAssign')?.addEventListener('click', async () => {
    const bookingId = document.getElementById('assignBookingId').value;
    const techUserId = document.getElementById('assignTechSelect').value;
    if (!bookingId || !techUserId) {
      showToast('Veuillez sélectionner un technicien.', 'error');
      return;
    }

    try {
      const res = await apiRequest(`/admin/bookings/${bookingId}/manual-assign`, {
        method: 'POST',
        body: JSON.stringify({ technician_user_id: techUserId }),
      });
      showToast(res.message || 'Dépannage assigné avec succès !', 'success');
      document.getElementById('manualAssignModal').classList.remove('active');
      refreshAllData();
    } catch (e) {
      showToast(e.message || "Erreur lors de l'assignation", 'error');
    }
  });

  // Admin Login Modal Form
  document.getElementById('adminLoginForm')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    const identifier = document.getElementById('loginIdentifier').value.trim();
    const password = document.getElementById('loginPassword').value;

    try {
      const res = await fetch(`${getApiBase()}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: identifier, phone: identifier, password }),
      });

      if (!res.ok) {
        throw new Error('Identifiants administrateur invalides.');
      }

      const data = await res.json();
      state.token = data.access_token;
      state.adminUser = data.user;
      localStorage.setItem('depango_admin_token', state.token);
      localStorage.setItem('depango_admin_user', JSON.stringify(data.user));

      document.getElementById('adminLoginModal').classList.remove('active');
      document.getElementById('adminNameDisplay').textContent = data.user.name || 'Super Admin';
      showToast('Connexion réussie à la console !', 'success');
      refreshAllData();
      startAutoRefresh();
    } catch (err) {
      showToast(err.message || 'Échec de connexion', 'error');
    }
  });

  // Logout
  document.getElementById('btnLogout')?.addEventListener('click', () => {
    localStorage.removeItem('depango_admin_token');
    localStorage.removeItem('depango_admin_user');
    state.token = '';
    state.adminUser = null;
    openLoginModal();
  });
}

function openLoginModal() {
  document.getElementById('adminLoginModal')?.classList.add('active');
}

window.openAssignModal = (bookingId, clientName, categoryId) => {
  document.getElementById('assignBookingId').value = bookingId;
  document.getElementById('assignBookingDesc').textContent = `${clientName} • ${categoryId.toUpperCase()}`;

  const select = document.getElementById('assignTechSelect');
  select.innerHTML = state.technicians
    .map((t) => {
      const isOnline = t.availability_status === 'online';
      return `<option value="${t.user_id}">${t.name} (${t.transport_mode === 'voiture' ? 'Voiture' : 'Moto'}) — ${isOnline ? '🟢 En Ligne' : '⚪ Pause'}</option>`;
    })
    .join('');

  document.getElementById('manualAssignModal').classList.add('active');
};

// --- Search & Filter Listeners ---
function setupSearchAndFilters() {
  // Fleet filters
  document.querySelectorAll('.radar-filter-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.radar-filter-btn').forEach((b) => b.classList.remove('active'));
      btn.classList.add('active');
      state.fleetFilter = btn.getAttribute('data-filter');
      renderFleet(state.fleet);
    });
  });

  document.getElementById('fleetSearchInput')?.addEventListener('input', () => {
    renderFleet(state.fleet);
  });

  // Missions filter
  document.getElementById('missionSearchInput')?.addEventListener('input', () => {
    renderMissions(state.missions);
  });
  document.getElementById('missionStatusFilter')?.addEventListener('change', () => {
    renderMissions(state.missions);
  });

  // Techs filter
  document.getElementById('techSearchInput')?.addEventListener('input', () => {
    renderTechnicians(state.technicians);
  });
  document.getElementById('techFilterKyc')?.addEventListener('change', () => {
    renderTechnicians(state.technicians);
  });
}
