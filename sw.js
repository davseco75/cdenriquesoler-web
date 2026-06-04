/* ================================================================
   Service Worker — MCD Enrique Soler App
   Estrategia híbrida:
   · Páginas HTML y datos (/data/*.json) → NETWORK-FIRST
     (siempre contenido fresco si hay internet; caché solo offline)
   · Imágenes, fuentes y librerías de CDN → CACHE-FIRST
     (rápidas y no cambian de nombre)
================================================================ */
const CACHE_NAME = 'es-app-v3';

const PRECACHE = [
  '/index.html',
  '/manifest.json',
  '/logo.png',
  '/icon-192.png',
  '/icon-512.png',
  '/apple-touch-icon.png',
];

/* ── Install: pre-cache app shell ── */
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(PRECACHE))
      .then(() => self.skipWaiting())
  );
});

/* ── Activate: limpia cachés antiguas ── */
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(
        keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k))
      ))
      .then(() => self.clients.claim())
  );
});

/* ── ¿Debe ir siempre a la red primero? (HTML y datos) ── */
function isFreshFirst(request) {
  if (request.mode === 'navigate' || request.destination === 'document') return true;
  if (request.url.includes('/data/')) return true;       // plantilla, partidos, noticias...
  if (request.url.endsWith('.html')) return true;
  return false;
}

/* ── Fetch ── */
self.addEventListener('fetch', event => {
  const { request } = event;
  if (request.method !== 'GET') return;

  /* NETWORK-FIRST para páginas y datos: contenido siempre actualizado */
  if (isFreshFirst(request)) {
    event.respondWith(
      fetch(request)
        .then(response => {
          if (response.ok && request.url.includes(self.location.origin)) {
            const clone = response.clone();
            caches.open(CACHE_NAME).then(cache => cache.put(request, clone));
          }
          return response;
        })
        .catch(() =>
          caches.match(request).then(cached =>
            cached || (request.destination === 'document' ? caches.match('/index.html') : undefined)
          )
        )
    );
    return;
  }

  /* CACHE-FIRST para estáticos (imágenes, fuentes, CDN) */
  event.respondWith(
    caches.match(request).then(cached => {
      if (cached) return cached;
      return fetch(request).then(response => {
        if (
          response.ok &&
          (request.url.includes(self.location.origin) ||
           request.url.includes('fonts.googleapis.com') ||
           request.url.includes('fonts.gstatic.com') ||
           request.url.includes('cdn.jsdelivr.net'))
        ) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(request, clone));
        }
        return response;
      });
    })
  );
});
