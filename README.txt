KLEREK KASIR v3.5.0 — SUPABASE MULTIUSER (7 November 2026)
=============================================================

PENTING: FILE SUDAH DIINTEGRASIKAN DENGAN SUPABASE, NAMUN CLOUD TIDAK AKTIF
SAMPAI PEMILIK MEMBUAT PROJECT DAN MENGISI URL + PUBLISHABLE KEY.
Tidak ada akses ke proyek Supabase pengguna, sehingga belum bisa mengisi kredensial
atau mengaktifkan database secara otomatis.

A. SETUP SUPABASE UNTUK PEMILIK TOKO
----------------------------------
1. Buka https://supabase.com/dashboard -> New Project.
2. Setelah proyek dibuat, masuk SQL Editor -> New query.
3. Copy SELURUH isi file supabase_setup.sql -> Run. Hanya sekali.
4. Project Settings -> API Keys: salin Publishable key (sb_publishable_...) atau
   legacy anon public key. Pada Project Settings -> Data API/General ambil Project URL.
   (Lokasi menu bisa berbeda bergantung tampilan dashboard.)
5. Edit supabase-config.js:
   url: 'https://PROJECT_ID.supabase.co',
   publishableKey: 'sb_publishable_...'
   Jangan pernah menaruh service_role atau secret key pada file GitHub publik!
6. Authentication -> Providers -> Email -> pastikan login email aktif. Jika email
   confirmation wajib, masing-masing kasir harus mengonfirmasi email terlebih dulu.
   Tambahkan domain GitHub Pages pada Authentication -> URL Configuration (Site URL)
   sesuai kebutuhan.
7. Backup JSON dari aplikasi lama. Upload ISI ZIP (bukan folder pembungkus) ke ROOT
   repositori GitHub Pages. File kunci: index.html, sw.js, supabase-config.js,
   supabase_setup.sql (boleh tidak upload SQL ke GitHub), icons, manifest.webmanifest.
8. Buka lagi URL HTTPS, lakukan hard reload/periksa pembaruan dari menu Lainnya.

B. CARA PEMAKAIAN 3 SHIFT / 6 KASIR
---------------------------------
1. Menu Lainnya -> Cloud Supabase & Multiuser.
2. Kepala toko: Daftar Akun -> Masuk -> Buat Toko -> Lihat Kode Undangan.
3. Setiap kasir: Daftar dengan email masing-masing -> Masuk -> Gabung Toko
   pakai kode undangan 36 karakter dari kepala toko.
4. Pemilik dapat mengubah peran anggota: Kasir (hanya transaksi kasir),
   Kepala Toko (boleh input settlement dan roster), Admin (kelola pengguna).
5. User mengisi shift masing-masing di menu Hitung seperti biasa.
   Shift 1 = 2 kasir, Shift 2 = 2 kasir, Shift 3 = 2 kasir.
   Mulai Shift 3 Kamis 22.00 dihitung ke tanggal kerja Jumat.
6. Setiap kasir disimpan sebagai dokumen terpisah per tanggal + shift + nomor kasir.
   Update antar HP melalui Supabase Realtime; tombol Ambil Data Terbaru tersedia.
7. Ada indikator Pending saat perubahan menunggu dikirim. Bila dua orang mengubah
   kasir yang SAMA bersamaan, server menolak update versi lama; buka Cloud untuk
   memilih Ambil versi cloud atau Timpa dengan versi saya (konfirmasi diperlukan).
8. Jika internet putus saat aplikasi terbuka, perubahan tersimpan sebagai draft lokal
   dan dikirim kembali setelah online. Tetap buat backup. Saat membuka aplikasi
   BARU saat offline, login/cloud mungkin tidak bisa dimuat karena Supabase JS
   memerlukan aset eksternal dan proses autentikasi. Jangan anggap data lokal
   sebagai data bersama sebelum status menunjukkan Cloud tersinkron.

C. DATA LAMA DAN KEAMANAN
------------------------
* Data lokal v3.3 tetap terpisah dan tidak dikirim ke cloud otomatis.
* Setelah login cloud, buka Cloud -> Unggah Riwayat Lokal (tanpa menimpa) untuk
  memindahkan data lama. Dokumen yang sudah ada di cloud TIDAK ditimpa.
* Backup JSON tetap tersedia. Restore JSON langsung dinonaktifkan ketika cloud
  aktif agar tidak menimpa data pengguna lain secara tak sengaja.
* Akses server dilindungi Supabase Auth, Row Level Security, peran anggota,
  serta fungsi SQL untuk pembaruan dengan revision. Kunci publik di browser aman
  bila RLS tetap aktif; jangan pernah menaruh secret/service role di file publik.
* Kode undangan hanya tersedia bagi admin. Admin dapat mengganti kode,
  mencabut akses pengguna, dan mengatur role. Kasir tidak dapat mengubah head
  atau roster, tetapi dapat melihat laporan toko anggota tersebut.
* PIN aplikasi lama HANYA kunci layar lokal, bukan pengganti password Cloud.
* Jika kuota gratis Supabase berubah, cek Usage di dashboard Supabase. Jangan
  mengasumsikan bahwa semua fitur online tersedia tanpa koneksi/proyek aktif.

D. PENGUJIAN
------------
Uji real-time dengan dua akun email/dua HP (koneksi internet) setelah
menjalankan SQL dan mengisi config. Uji tanggal Shift 3 pukul 22.00,
edit slot kasir berbeda, edit slot kasir sama (konflik), kepala toko,
dan impor data lokal sebelum operasional.

Buka offline/lokal: python -m http.server 8000
lalu kunjungi http://localhost:8000/index.html.

RUMUS TETAP: KLEREK = PICKUP - eTrans - PLN.
Data kasir dan laporan v3.3 dipertahankan.

E. PERUBAHAN v3.5.0 (7 NOVEMBER 2026)
-----------------------------------
- Shift 1: 2 kasir; Shift 2: 2 kasir; Shift 3: 2 kasir. Total 6 kasir.
- Shift 3 masuk pukul 22:00 pada H-1, dihitung ke tanggal kerja H.
- Tab Riwayat menampilkan SATU BULAN kalender pada satu waktu (pilihan bulan,
  bulan sebelum/berikutnya, cari nama/tanggal di bulan tersebut, CSV per bulan).
  Bulan lain tetap dapat diakses; mengubah filter bulan TIDAK menghapus data.
- Rekap semua riwayat tetap bisa diakses melalui Lainnya, CSV semua tanggal.
- Data kasir ke-3 Shift 3 dari versi 3.4 yang pernah berisi transaksi disimpan
  sebagai ARSIP HISTORIS, bukan input aktif. Nominal historis ikut laporan
  bulanan dan ekspor riwayat. Jika tidak ada isian, slot lama diabaikan.
- SQL Supabase dari v3.4 tidak perlu dijalankan ulang bila sudah dipasang;
  skema database sudah mendukung slot 1-2 di Shift 3.
- PENTING: Supabase butuh Project URL + publishable key, SQL dan akun agar
  multiuser benar-benar berjalan. Belum ada kredensial Supabase di ZIP.
- Sebelum memasang versi baru, backup JSON melalui aplikasi versi lama.
