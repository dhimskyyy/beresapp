# DESIGN SYSTEM & UI/UX SPECIFICATION (design.md)

Dokumen ini mendefinisikan identitas visual, komponen antarmuka (*UI Design System*), panduan pengalaman pengguna (*UX Guidelines*), dan spesifikasi layar untuk ekosistem **Beres** (Beres User, Beres Mitra, dan Beres Web Admin).

---

## 1. IDENTITAS VISUAL & TEMA BRAND

Aplikasi Beres membawa kesan **terpercaya, andal, sigap, dan profesional**.

### 1.1. Palet Warna (Color Palette)

| Nama Token | Hex Code | Deskripsi & Penggunaan |
| :--- | :--- | :--- |
| **Primary (Beres Blue)** | `#1E40AF` (Tailwind `blue-800`) | Warna utama brand, tombol primer, header aktif, status confirmed. Melambangkan profesionalisme dan kepercayaan. |
| **Primary Light** | `#3B82F6` (Tailwind `blue-500`) | Aksen interaktif, badge status aktif, link, highlight kategori. |
| **Secondary (Safety Amber)** | `#F59E0B` (Tailwind `amber-500`) | Warna aksen tukang/keamanan, status *Pending Verification*, rating bintang, banner perhatian. |
| **Success (Ready Green)** | `#10B981` (Tailwind `emerald-500`) | Status *Pekerjaan Selesai*, pembayaran lunas, verifikasi disetujui, saldo dompet. |
| **Danger / Alert (Crimson)** | `#EF4444` (Tailwind `red-500`) | Status *Suspend*, tolak verifikasi KTP, batalkan tiket, hapus data. |
| **Neutral Dark (Text)** | `#0F172A` (Tailwind `slate-900`) | Teks utama, judul (*Headings*), ikon prioritas tinggi. |
| **Neutral Muted** | `#64748B` (Tailwind `slate-500`) | Teks sekunder, deskripsi bantuan, placeholder input. |
| **Background Light** | `#F8FAFC` (Tailwind `slate-50`) | Latar belakang layar aplikasi mobile dan konten web admin. |
| **Surface White** | `#FFFFFF` | Card latar belakang, bottom sheet, modal dialog, container form. |

### 1.2. Tipografi (Typography)
* **Font Family:** `Inter` atau `Plus Jakarta Sans` (Google Fonts).
* **Skala Tipografi:**
  * **H1 / Display:** 24px - 28px, SemiBold / Bold (Judul Beranda, Total Saldo, Header Layar).
  * **H2 / Section Title:** 18px - 20px, SemiBold (Judul Section, Nama Tukang, Nama Kategori).
  * **Body Regular:** 14px - 15px, Regular (Deskripsi keluhan, pesan chat, rincian biaya).
  * **Body Medium / Caption:** 12px - 13px, Medium (Timestamp, badge status, info rating, label input).
  * **Small / Micro:** 10px - 11px, Regular (Legal text, helper notes di bawah input).

---

## 2. DESAIN IKON & KATEGORI LAYANAN

Setiap kategori layanan memiliki warna aksen lembut (*subtle container background*) dan ikon yang mudah dikenali:

| Kategori | Nama Ikon (Lucide / Material) | Warna Background Ikon |
| :--- | :--- | :--- |
| **AC** | `snowflake` / `ac_unit` | `#EFF6FF` (Soft Blue) |
| **Cleaning** | `sparkles` / `cleaning_services` | `#ECFDF5` (Soft Emerald) |
| **Elektronik** | `tv` / `devices` | `#F5F3FF` (Soft Purple) |
| **Las** | `flame` / `precision_manufacturing` | `#FFF7ED` (Soft Orange) |
| **Bangunan** | `home` / `foundation` | `#FEF3C7` (Soft Amber) |
| **Besi & Baja** | `shield` / `architecture` | `#F1F5F9` (Soft Slate) |
| **Bengkel Motor** | `bike` / `two_wheeler` | `#FEE2E2` (Soft Red) |
| **Bengkel Mobil** | `car` / `directions_car` | `#E0F2FE` (Soft Sky) |
| **Pengrajin Kayu** | `hammer` / `carpenter` | `#FEF3C7` (Soft Wood) |
| **Plumbing** | `droplet` / `plumbing` | `#E0F2FE` (Soft Cyan) |

---

## 3. SPESIFIKASI LAYAR APLIKASI USER (BERES APP)

### 3.1. Layar Beranda (Home Screen)
* **Top Header:** Salam sapa pengguna, foto profil, dan kartu ringkasan alamat rumah yang sedang aktif.
* **Banner Edukasi / Promo:** Slider informasi proteksi garansi pengerjaan & kemudahan pesan tukang.
* **Grid 10 Kategori Layanan:** Tata letak 2 baris 5 kolom atau 3 kolom yang responsif dengan animasi sentuh (*haptic feedback*).
* **Pekerjaan Sedang Berjalan (Active Ticket Card):** Jika ada tiket yang sedang aktif, muncul kartu melayang di bagian atas dengan progress bar (contoh: *"Tukang Ahmad sedang menuju lokasimu - Estimasi 15 menit"*).

### 3.2. Layar Pembuatan Tiket Keluhan (Create Ticket)
* **Header:** Pemilihan kategori yang sudah dipilih beserta ikonnya.
* **Input Judul & Deskripsi Masalah:** Form deskriptif dengan saran kata kunci (misal: *"AC netes air / bau tidak sedap"*).
* **Multi-Photo Upload Section:** Tombol ambil dari kamera / galeri dengan thumbnail preview dan tombol hapus (X).
* **Mini Map Lokasi (Leaflet / OSM):** Menampilkan peta interaktif untuk menggeser pin lokasi alamat rumah secara akurat.
* **Tombol Aksi Utama:** *"Kirim Permintaan ke Tukang"* (Full-width sticky bottom button).

### 3.3. Layar Bidding & Pemilihan Tukang (Offers Screen)
* **Daftar Penawaran Masuk (Live Stream):** Kartu untuk setiap tukang yang mengajukan bid.
  * Foto profil, nama lengkap, lencana keahlian, jarak dari lokasi user.
  * Rating bintang dan jumlah review pelanggan sebelumnya.
  * Nominal estimasi biaya (contoh: `Rp 150.000`).
  * Pesan/catatan tukang (*"Siap meluncur, alat cuci AC lengkap"*).
* **Tombol Aksi:** Tombol primer **"Lock Tukang"** dan tombol sekunder **"Lihat Profil Detail"**.

### 3.4. Layar Pelacakan & Pengerjaan (Active Job & Tracking)
* **Peta Layar Penuh (Tracking Map):**
  * Pin merah di lokasi rumah user.
  * Pin biru bergerak menampilkan posisi live GPS tukang saat status `ON_THE_WAY`.
* **Bottom Sheet Interaktif:**
  * Status terkini: *"Menuju Lokasi"* / *"Tiba di Lokasi & Diagnosa"* / *"Pengerjaan Berlangsung"*.
  * Tombol pintas **Chat In-App**.
  * Kartu Rincian Biaya Final (Rincian jasa & suku cadang) dengan tombol **"Setujui Biaya"**.
  * Preview foto Sebelum & Sesudah pengerjaan.
* **Modal Pembayaran:** Muncul otomatis saat pekerjaan selesai:
  * Pilihan DOKU (BCA, BRI, Mandiri, QRIS) atau Tunai.

---

## 4. SPESIFIKASI LAYAR APLIKASI TUKANG (BERES MITRA)

### 4.1. Layar Onboarding & Registrasi KTP
* **Step 1 - Biodata Diri:** Nama, tanggal lahir (datepicker), umur otomatis terhitung, nomor WhatsApp.
* **Step 2 - Keahlian:** Pilihan multi-select checkbox untuk 10 kategori keahlian.
* **Step 3 - Rekening Payout:** Input nama bank/e-wallet (BCA, BRI, BNI, Mandiri, DANA, GoPay, OVO, ShopeePay), nomor rekening, dan nama pemilik.
* **Step 4 - Upload KTP:** Frame panduan kamera untuk memotret KTP secara tegak lurus dan terang.
* **Layar Status Verifikasi:** Ilustrasi jam pasir dengan teks: *"Dokumen Anda sedang ditinjau oleh Admin Beres (Maks. 1x24 jam)"*.

### 4.2. Layar Radar Tiket (Job Radar / Feed)
* **Header Status:** Toggle tombol **Online / Offline**.
* **Banner Peringatan Suspend:** Jika tukang disuspend, area radar digantikan kartu merah bertuliskan: *"Akun Anda sedang disuspend. Waktu tersisa: 2 Hari 14 Jam. Alasan: [Alasan Admin]"*.
* **Kartu Tiket Masuk:**
  * Jarak tempuh (misal: `2.4 km dari lokasi Anda`).
  * Kategori dan judul keluhan user.
  * Foto keluhan dengan modal zoom.
  * Tombol **"Ajukan Penawaran"** (Input estimasi harga dan catatan).

### 4.3. Layar Tahapan Kerja (Job Workflow Screen)
* **Tombol Aksi Bertahap (Single Clear Action Button):**
  * Step 1: **"Mulai Berangkat (Menuju Lokasi)"** $\rightarrow$ Mengaktifkan transmisi GPS latar belakang.
  * Step 2: **"Saya Sudah Tiba"** $\rightarrow$ Membuka form input rincian biaya diagnosa.
  * Step 3: **"Ambil Foto Sebelum Kerja"** $\rightarrow$ Membuka kamera, wajib foto sebelum bisa klik Mulai Kerja.
  * Step 4: **"Ambil Foto Sesudah Kerja"** $\rightarrow$ Wajib foto hasil kerja sebelum bisa klik Selesai.
  * Step 5: **"Konfirmasi Selesai & Tagih"** $\rightarrow$ Menunggu user membayar via DOKU atau konfirmasi tunai.

### 4.4. Layar Dompet Digital & Penarikan Dana (Wallet Screen)
* **Kartu Saldo:** Menampilkan total saldo aktif yang siap ditarik (contoh: `Rp 850.000`).
* **Tombol "Tarik Dana" (Withdraw):** Modal pilihan rekening penampung yang telah didaftarkan + input nominal penarikan.
* **Riwayat Mutasi Saldo:** Daftar transaksi masuk dari order yang selesai dan transaksi keluar dari penarikan dana.

---

## 5. SPESIFIKASI DASHBOARD WEB ADMIN (REACT + VITE + TAILWIND)

### 5.1. Layout & Navigasi
* **Sidebar Kiri (Dark Slate Theme):**
  * Logo Beres dengan status admin.
  * Menu: *Dashboard*, *Verifikasi KTP*, *Lacak Tukang (GPS)*, *Manajemen Tukang*, *Manajemen User*, *Tiket & Pekerjaan*, *Pencairan Dana*.
* **Top Bar:** Jam real-time, indikator server Firebase terhubung, profil Admin, dan tombol Logout.

### 5.2. Layar Verifikasi KTP (KYC Screen)
* **Tab Navigasi:** `Menunggu Verifikasi`, `Terverifikasi`, `Ditolak`.
* **Tabel Antrean:** Tanggal daftar, nama mitra, usia, kategori yang dipilih, thumbnail KTP.
* **Modal Inspeksi KTP:**
  * Tampilan foto KTP resolusi tinggi dengan kontrol Zoom & Rotasi.
  * Form perbandingan data teks (nama dan tanggal lahir).
  * Tombol Hijau: **"Setujui Mitra (Approve)"**.
  * Tombol Merah: **"Tolak Mitra (Reject)"** dengan textarea input alasan penolakan.

### 5.3. Layar Lacak GPS Tukang (Real-time Live Map)
* **Peta Fullscreen (React-Leaflet + OpenStreetMap):**
  * Marker Biru: Tukang sedang *Online / Idle*.
  * Marker Kuning: Tukang sedang *Menuju Lokasi*.
  * Marker Hijau: Tukang sedang *Mengerjakan Order*.
  * Marker Abu-abu: Tukang *Offline*.
* **Sidebar Peta Interaktif:** Pencarian tukang berdasarkan nama/kategori. Klik nama langsung membuat kamera peta melakukan animasi *flyTo* ke titik koordinat tukang.

### 5.4. Layar Manajemen Tukang & Fitur Suspend
* **Tabel Mitra Lengkap:** Kolom ID, Nama, No. HP, Keahlian, Rating, Total Order Selesai, Status Akun (`Aktif` / `Suspended`).
* **Aksi Suspend 3 Hari:**
  * Tombol dropdown pada baris tukang: **"Suspend 3 Hari"**.
  * Modal konfirmasi: Input alasan suspensi (contoh: *"Membatalkan sepihak / perilaku tidak sopan"*).
  * Sistem mencatat tanggal `suspendedUntil` dan status `isSuspended: true`.
  * Tombol **"Cabut Suspend (Unsuspend)"** tersedia jika sanksi ingin dibatalkan lebih awal.

---

## 6. PRINSIP PENGALAMAN PENGGUNA (UX BEST PRACTICES)
1. **Zero Confusion Status:** Setiap pergantian status pekerjaan disertai getaran halus (*haptic*), perubahan warna status badge, dan teks petunjuk yang sangat jelas bagi pengguna awam.
2. **Offline Resilience:** Jika koneksi tukang tidak stabil saat berada di rumah pelanggan, input data dan foto disimpan di antrean lokal (*local draft*) dan otomatis diunggah saat koneksi pulih kembali.
3. **Camera-First Workflow:** Untuk menjamin kejujuran kondisi pekerjaan, foto keluhan dan foto hasil kerja dapat langsung diambil dari kamera aplikasi dengan watermark tanggal dan waktu pengerjaan.
