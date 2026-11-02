/* KLEREK KASIR – PWA shell cache repair.
   Version bump ensures Chrome can switch away from stale offline fallback.
   Does not store Firebase Authentication/Firestore traffic. */
const CACHE_NAME = 'klerek-shell-repair-20261103-v1';
const SHELL = [
  './', './index.html', './style.css', './app.js', './cloud.js',
  './firebase-config.js', './manifest.webmanifest',
  './icons/icon-192.png', './icons/icon-512.png',
  './icons/icon-maskable-512.png', './icons/apple-touch-icon.png'
];
const APP_HOME = new URL('./index.html', self.registration.scope).href;

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    // One missing optional icon must not fail installation of the entire app.
    const results = await Promise.allSettled(SHELL.map(async (path) => {
      const url = new URL(path, self.registration.scope).href;
      const response = await fetch(url, {cache:'reload'});
      if (!response.ok) throw new Error(`${path}: HTTP ${response.status}`);
      await cache.put(url, response);
    }));
    for (const [i, r] of results.entries()) if (r.status === 'rejected') {
      console.warn('[Klerek SW] File not cached:', SHELL[i], String(r.reason));
    }
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter(k => k.startsWith('klerek-') && k !== CACHE_NAME).map(k => caches.delete(k)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== self.location.origin || !url.pathname.startsWith(new URL(self.registration.scope).pathname)) {
    // Never intercept private cloud/API requests or cross-origin Firebase SDK calls.
    return;
  }
  if (req.mode === 'navigate') {
    event.respondWith((async () => {
      try {
        const live = await fetch(req);
        if (live.ok) {
          const cache = await caches.open(CACHE_NAME);
          // Cache the entry point, not a query-specific failed response.
          await cache.put(APP_HOME, live.clone());
          return live;
        }
        const cached = await caches.match(APP_HOME);
        return cached || live;
      } catch (e) {
        return (await caches.match(APP_HOME)) || new Response(
          '<!doctype html><html lang="id"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><body style="font-family:system-ui;padding:24px"><h2>KLEREK KASIR</h2><p>Halaman belum tersimpan untuk offline. Sambungkan internet dan muat ulang.</p></body></html>',
          {status: 503, headers: {'Content-Type':'text/html; charset=utf-8'}}
        );
      }
    })());
    return;
  }
  event.respondWith((async () => {
    const cached = await caches.match(req);
    if (cached) return cached;
    const fresh = await fetch(req);
    if (fresh.ok) {
      const cache = await caches.open(CACHE_NAME);
      await cache.put(req, fresh.clone());
    }
    return fresh;
  })());
});
