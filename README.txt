# KLEREK KASIR — PWA Multi Tema, Mode Offline

Ini adalah proyek PWA siap dipublikasikan, **BUKAN berkas APK**. Seluruh tampilan dan perhitungan bekerja di perangkat; tidak ada server/database/API untuk data kasir.

## Apa arti 100% offline?
- **Setelah instalasi PWA pertama kali berhasil, semua fitur perhitungan, rekap, penggantian tema, riwayat, backup, restore dan CSV bekerja tanpa Wi-Fi/kuota.**
- PWA memerlukan **SATU KALI** akses ke URL HTTPS untuk instalasi dan pengisian cache (contoh GitHub Pages atau hosting statis lain). File `index.html` yang dibuka dari folder Download (`file://`) TIDAK bisa dipasang sebagai PWA melalui Chrome.
- Bila Anda tidak ingin memakai internet bahkan satu kali, gunakan `KLEREK_KASIR_HTML_OFFLINE.html` yang disediakan terpisah, atau APK native yang sudah dibangun; PWA tidak bisa sepenuhnya dipasang pertama kali dari file lokal di Chrome Android.
- Kode aplikasi tidak mengandung analitik, tracking, API, atau sumber daya eksternal. Browser bisa memeriksa pembaruan file service worker saat ada internet; itu bukan pengiriman data kasir.

## Cara mempublikasikan agar dapat diinstal di HP
1. Ekstrak ZIP ini dan unggah **isi folder** (index.html, sw.js, manifest.webmanifest, icons/) ke hosting statis HTTPS, misalnya GitHub Pages.
2. Buka URL HTTPS di Chrome Android, tunggu halaman selesai dimuat.
3. Menu Chrome ⋮ → **Instal aplikasi** / **Tambahkan ke Layar Utama** (atau tekan tombol instal pada menu Lainnya di aplikasi).
4. Setelah ikon terpasang, hidupkan **Mode Pesawat** untuk menguji: buka Klerek Kasir → isi transaksi → tutup → buka lagi → pastikan data masih ada.

## Privasi dan penyimpanan
- Data disimpan **lokal dalam penyimpanan situs PWA di HP**, bukan di database server atau file HTML.
- Data dari file .html versi lama **TIDAK otomatis berpindah** ke PWA. Ekspor Backup JSON dari HTML lama → impor/Pulihkan pada PWA baru.
- Jangan menghapus data situs Chrome, melepas aplikasi, atau mereset HP tanpa backup. Cadangkan data JSON setiap akhir shift; data dapat hilang jika storage browser dibersihkan.
- Ganti tema tidak mengubah perhitungan atau data.

## Rumus
Klerek = Pickup − eTrans − PLN, sesuai versi HTML yang telah berfungsi. Setiap Shift 1 & 2 memiliki 2 kasir.

## Uji lokal untuk pengembang
Jalankan `python -m http.server 8000` di folder proyek, lalu buka `http://localhost:8000/`. Localhost dianggap secure context untuk pengujian service worker. Tidak mengubah cara instalasi dari file Download di HP.
