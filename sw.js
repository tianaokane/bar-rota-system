const CACHE_NAME = 'su-bar-rota-v1'

// Pages to cache for offline access
const PRECACHE = [
  '/index.html',
  '/login.html',
  '/rota.html',
  '/my-shifts.html',
  '/availability.html',
]

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(PRECACHE))
  )
  self.skipWaiting()
})

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  )
  self.clients.claim()
})

self.addEventListener('fetch', event => {
  // Only handle GET requests
  if (event.request.method !== 'GET') return

  // Never intercept Supabase API calls — always go network
  if (event.request.url.includes('supabase.co')) return

  event.respondWith(
    fetch(event.request)
      .then(response => {
        // Cache successful HTML page responses
        if (response.ok && event.request.destination === 'document') {
          const clone = response.clone()
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone))
        }
        return response
      })
      .catch(() => {
        // Network failed — try cache
        return caches.match(event.request)
          .then(cached => cached ?? caches.match('/index.html'))
      })
  )
})