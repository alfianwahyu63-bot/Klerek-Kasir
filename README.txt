KLEREK KASIR v3.5.1 - Konfigurasi Supabase terpasang (7 November 2026)
===================================================================

STATUS:
- Project URL + Supabase publishable key SUDAH dipasang di supabase-config.js.
- BUKAN bukti cloud sudah online; masih perlu SQL, Email Auth, unggah ke GitHub Pages,
  pembuatan akun, serta uji sinkronisasi pada dua HP.
- Aplikasi v3.5.1 tetap 3 shift x 2 kasir = 6 kasir; Shift 3 mulai H-1 jam 22.00
  dan masuk laporan H. Riwayat tampil satu bulan kalender pada satu waktu.

AKTIVASI (kerjakan berurutan):
1. Login ke https://supabase.com/dashboard dan pilih proyek yang sudah dibuat.
2. Buka SQL Editor > New Query > salin seluruh isi supabase_setup.sql > Run.
   Ini membuat tabel, fungsi RPC, RLS, roles, dan publikasi realtime.
   Jika sebelumnya pernah dijalankan, tidak perlu mengulang.
3. Buka Authentication > Providers > Email: pastikan Email aktif.
   Jika konfirmasi email wajib, pengguna harus mengonfirmasi dulu.
4. Di Authentication > URL Configuration, atur Site URL:
   https://alfianwahyu63-bot.github.io/Klerek-Kasir/
   Jika perlu redirect, tambahkan URL HTTPS yang sama pada Redirect URLs.
5. BACKUP JSON melalui versi lama sebelum mengunggah aplikasi baru.
6. Ekstrak ZIP; upload isinya ke root repo GitHub Pages Klerek-Kasir.
   File yang diperlukan: index.html, sw.js, manifest.webmanifest,
   supabase-config.js, dan folder icons. File SQL tidak wajib dipublikasikan.
7. Setelah GitHub Pages terbit, muat ulang atau gunakan Periksa Pembaruan.
8. Buka Lainnya > Cloud Supabase & Multiuser > Daftar Akun dan Masuk.
   Admin pilih Buat Toko, lalu bagikan kode undangan dari menu Cloud.
9. Kasir lain daftar/login dengan email masing-masing lalu Gabung Toko.
   Uji 2 akun di 2 HP, input kasir berbeda, refresh dan cocokkan nominal.
10. Jika perlu: Cloud > Unggah Riwayat Lokal (tanpa menimpa).

PENTING:
- Publishable key aman untuk browser HANYA ketika RLS dan izin tabel benar.
- Jangan simpan service_role, sb_secret, password database atau password kasir
  ke GitHub ataupun mengirimkannya ke orang lain.
- Jangan menjalankan bisnis dengan sinkronisasi asumsi berhasil: periksa status
  Cloud tersinkron, Pending=0, Konflik=0 pada setiap HP.
- Bila koneksi offline, perubahan bisa berada dalam draft lokal. Periksa lagi
  saat online sebelum menganggap semua perubahan masuk database.
- Untuk laporan bulan lain gunakan navigasi bulan pada tab Riwayat.

Pengujian internal terbatas pada pemeriksaan struktur dan sintaks file,
belum uji real-time pada proyek Supabase karena tidak ada akses dashboard
atau akun pengguna ke project.
