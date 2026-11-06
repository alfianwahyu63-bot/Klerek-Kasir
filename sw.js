/* KLEREK KASIR v3.5.0 · Cloud-enabled PWA shell.
   Cache hanya file yang benar-benar ada di proyek ini.
   Rekap, nama kasir, dan riwayat disimpan lokal oleh aplikasi, bukan service worker. */
const CACHE_NAME = 'klerek-shell-v3.5.0-20261106';
const SHELL = [
  './', './index.html', './supabase-config.js', './manifest.webmanifest',
  './icons/icon-192.png', './icons/icon-512.png',
  './icons/icon-maskable-512.png', './icons/apple-touch-icon.png'
];
const APP_HOME = new URL('./index.html', self.registration.scope).href;

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    await Promise.all(SHELL.map(async (path) => {
      const url = new URL(path, self.registration.scope).href;
      const response = await fetch(url, {cache:'reload'});
      if (!response.ok) throw new Error(`${path}: HTTP ${response.status}`);
      await cache.put(url, response);
    }));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter(key => key.startsWith('klerek-') && key !== CACHE_NAME).map(key => caches.delete(key)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin || !url.pathname.startsWith(new URL(self.registration.scope).pathname)) return;

  if (request.mode === 'navigate') {
    event.respondWith((async () => {
      try {
        const live = await fetch(request);
        if (live.ok) {
          const cache = await caches.open(CACHE_NAME);
          await cache.put(APP_HOME, live.clone());
          return live;
        }
        return (await caches.match(APP_HOME)) || live;
      } catch (_) {
        return (await caches.match(APP_HOME)) || new Response(
          '<!doctype html><html lang="id"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><body style="font-family:system-ui;padding:24px"><h2>KLEREK KASIR</h2><p>Buka aplikasi saat online satu kali untuk menyiapkan akses offline.</p></body></html>',
          {status: 503, headers: {'Content-Type': 'text/html; charset=utf-8'}}
        );
      }
    })());
    return;
  }
  event.respondWith((async () => {
    const cached = await caches.match(request);
    if (cached) return cached;
    const live = await fetch(request);
    if (live.ok) {
      const cache = await caches.open(CACHE_NAME);
      await cache.put(request, live.clone());
    }
    return live;
  })());
});
