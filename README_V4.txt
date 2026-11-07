KLEREK KASIR v4.0.0 — 3 SHIFT, 6 KASIR, SUPABASE & MONITORING
Tanggal: 7 November 2026
==================================================================

FILE YANG HARUS DIPASANG
1. KLEREK_KASIR_v4.0.0_GITHUB.zip — upload seluruh isi ZIP ke folder root
   repositori GitHub Pages. File index.html harus di ROOT.
2. KLEREK_KASIR_v4.0.0_SUPABASE_PATCH.txt — jalankan di Supabase SQL Editor.
   Patch ini adalah kelanjutan SQL v3.5 + patch dua kasir yang sebelumnya
   sudah sukses (lihat screenshot). Patch tidak menghapus transaksi lama.

CARA UPGRADE YANG AMAN
1. Pada aplikasi lama, gunakan Backup Data JSON dan simpan baik-baik.
2. Buka https://supabase.com/dashboard/project/nflqhjevxklutbymdrwf/sql/new
   Salin seluruh isi KLEREK_KASIR_v4.0.0_SUPABASE_PATCH.txt, klik RUN.
   Kalau gagal, JANGAN gunakan transaksi bersama dahulu; catat pesan error.
3. Unggah ISI ZIP aplikasi ke repositori GitHub Klerek-Kasir (bukan ZIP-nya).
   Pastikan index.html, sw.js, manifest.webmanifest, supabase-config.js
   serta folder icons ada di root repo.
4. Jika muncul '404 Site not found', periksa Settings > Pages > Build and
   deployment > Deploy from a branch > main > /(root); pastikan repo Public
   atau punya plan yang mendukung Pages private. Periksa Actions deployment.
   URL yang dikonfigurasi di Supabase Auth:
   https://alfianwahyu63-bot.github.io/Klerek-Kasir/
5. Muat ulang aplikasi dua kali atau pilih Periksa Pembaruan. Bila install
   PWA sebelumnya, pastikan versi yang terlihat menjadi v4.0.0.
6. Login admin di Lainnya > Cloud Supabase & Multiuser. Undang 6 kasir
   dan satu kepala toko; admin membagi satu akun ke setiap slot melalui
   Lainnya > Penugasan Slot Kasir. Kasir yang belum ditugaskan tidak dapat
   mengunggah transaksi atau menutup laporan ke server v4.
7. Test: kasir Shift 1-1 isi Pickup/eTrans/PLN dari HP pertama, tunggu
   pending=0, ketuk Tutup & Kirim. Kepala toko dari HP kedua melihat
   menunggu, verifikasi kas aktual dan Setujui atau Revisi. Pastikan
   laporan approved terkunci saat kasir mencoba mengedit.
8. Uji offline dengan mematikan internet saat sudah login dan toko terbuka;
   input, nyalakan internet dan cek Pending=0 serta Konflik=0. Reopen
   aplikasi dalam keadaan offline setelah logout/restart tidak dijamin
   memulihkan sesi cloud karena SDK Auth membutuhkan koneksi.

FITUR V4
- Dashboard 6 kasir: menunggu/approved/revisi/belum kirim, peringatan selisih.
- Tutup laporan per kasir dengan kunci server, approval kepala toko,
  revisi dengan alasan, buka ulang laporan oleh admin (jejak audit).
- Admin menugaskan satu kasir per shift+slot, sistem 3 shift x 2 kasir.
- Shift 3 dimulai 22.00 H-1 dan dilaporkan ke tanggal kerja H.
- Audit siapa yang mengedit/mengubah status di CLOUD (sejak patch v4).
  Data lokal sebelum patch tidak memiliki jejak pelaku yang dapat diverifikasi.
- Cloud queue offline dan optimistic locking versi dokumen; konflik tidak
  otomatis menimpa dokumen orang lain.
- Kalender status, rekap selisih per kasir setelah verifikasi kas aktual,
  total per shift, statistik dan laporan bulanan CSV/PDF.
- WhatsApp: share teks melalui menu, membutuhkan tindakan pengguna.
- Multi-toko: ringkasan toko-toko yang akunnya sudah menjadi anggota.
- Backup per tanggal: snapshot harian maksimum 35 hari, manual serta
  otomatis saat kepala/admin online dengan aplikasi terbuka sesudah
  pukul 21.00 atau setelah semua laporan disetujui. Restore hanya untuk
  DOKUMEN YANG HILANG, tidak menimpa data yang sudah ada.

PENJELASAN PENTING
- Selisih kas per kasir = kas aktual yang diinput kepala toko MINUS hasil
  Klerek kasir. Ini hanya berlaku ketika kepala toko melakukan verifikasi
  aktual; jangan anggap hasil Klerek = kekurangan/kelebihan uang nyata.
- Tidak ada notifikasi push otomatis saat aplikasi tertutup; notifikasi
  v4 adalah PERINGATAN DALAM aplikasi. Laporan WhatsApp dikirim manual.
- Supabase realtime bekerja ketika online, tetapi status akan dipolling
  berkala sebagai fallback. Jika offline, periksa ulang saat online.
- Cloud backup di sini adalah snapshot per hari, BUKAN backup penuh
  otomatis seluruh database Supabase. Buat backup JSON independen.
- Riwayat per bulan adalah PEMILAHAN TAMPILAN, bukan penghapusan data
  lebih lama. Jangan menghapus tabel untuk mengubah bulan.
- Akun ke-3 di Shift 3 dari versi lama tetap ada di arsip lokal/JSON,
  tetapi slot tersebut tidak boleh diinput/diunggah lagi.
- Dashboard GitHub Pages 404 sebelumnya belum diperbaiki otomatis.
- Pengujian yang dilakukan: validasi sintaks JS & simulasi browser dengan
  Supabase mock dua toko, tutup shift, approval, lock, menu dan laporan.
  Eksekusi SQL & sinkronisasi nyata pada proyek Supabase milik pengguna
  MASIH PERLU DICEK pada dua akun perangkat berbeda setelah terpasang.

KEAMANAN
- Jangan menaruh service_role key, sb_secret key atau password database
  di GitHub. ZIP hanya memuat publishable browser key sesuai input pengguna.
- RLS dan RPC harus aktif, tidak cukup hanya memasukkan Project URL/key.
- Jika SQL PATCH gagal, fitur v4 memblokir input cloud baru agar tidak
  melanggar hak akses. Simpan pesan error untuk diperbaiki.
