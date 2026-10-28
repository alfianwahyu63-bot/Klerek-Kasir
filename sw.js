/* KLEREK KASIR — cache-first offline PWA; no analytics, API, push, or sync. */
const CACHE_NAME = 'klerek-kasir-app-v4-20261028';
const APP_SHELL = ['./','./index.html','./manifest.webmanifest',
  './icons/icon-192.png','./icons/icon-512.png','./icons/icon-maskable-512.png',
  './icons/apple-touch-icon.png'];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(key => key.startsWith('klerek-kasir-app-') && key !== CACHE_NAME).map(key => caches.delete(key))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  const url = new URL(event.request.url);
  // PWA tidak menghubungi layanan pihak ketiga.
  if (url.origin !== self.location.origin) {
    event.respondWith(new Response('Aplikasi ini hanya menggunakan sumber daya lokal.',{status:403}));
    return;
  }
  if (event.request.mode === 'navigate') {
    event.respondWith(caches.match(new URL('./index.html', self.registration.scope))
      .then(response => response || new Response('Cache belum tersedia. Instal aplikasi saat online.',{status:503}))
    );
    return;
  }
  event.respondWith(caches.match(event.request)
    .then(response => response || new Response('Aset tidak tersedia secara offline.',{status:404}))
  );
});
