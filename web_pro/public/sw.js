const CACHE_NAME = 'techconnect-pro-v1';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', (event) => {
  // Pass through fetch requests for real-time WebSocket / API
  event.respondWith(fetch(event.request).catch(() => caches.match(event.request)));
});

// WebPush Fallback Handler
self.addEventListener('push', (event) => {
  const data = event.data ? event.data.json() : {};
  const title = data.title || 'Nouvelle Mission TechConnect !';
  const options = {
    body: data.body || 'Un client requiert votre intervention immédiate.',
    icon: '/icon-192.png',
    badge: '/icon-192.png',
    vibrate: [200, 100, 200]
  };
  event.waitUntil(self.registration.showNotification(title, options));
});
