# DEVELOPMENT ROADMAP & CHECKLIST (roadmap.md)

Dokumen ini berisi peta jalan pengembangan bertahap (*Step-by-Step Milestone*) untuk membangun ekosistem **Beres** secara terstruktur, lengkap dengan *checklist* tugas yang dapat dilacak kemajuannya.

---

## RINGKASAN FASE PENGEMBANGAN

| Fase | Fokus Utama | Target Luaran |
| :--- | :--- | :--- |
| **Fase 1** | Inisialisasi & Struktur Repositori | Scaffolding Flutter `mobile/` dan React Vite `admin/` |
| **Fase 2** | Dashboard Web Admin (React) | Verifikasi KTP, Peta Lacak Tukang GPS, Fitur Suspend 3 Hari |
| **Fase 3** | Autentikasi Mobile & Profil Mitra | Login/Register User & Tukang, Upload KTP, Data Rekening/E-Wallet |
| **Fase 4** | Order Matching & Bidding System | Posting Tiket User, Broadcast Notif, Bidding Tukang, Lock Tukang |
| **Fase 5** | Pelacakan GPS & Siklus Kerja | Live Tracking Leaflet, Input Tagihan Final, Foto Before/After |
| **Fase 6** | Realtime In-App Chat | Obrolan Teks & Kirim Foto Realtime di Firestore |
| **Fase 7** | Payment Gateway DOKU & Dompet | Integrasi Webhook DOKU, Saldo Dompet Mitra, Pencairan Dana |
| **Fase 8** | Pengujian & Peluncuran | Security Rules, Uji Coba Lapangan, Build APK/iOS & Web Hosting |

---

## CHECKLIST TUGAS DETAIL PER FASE

### FASE 1: INISIALISASI & STRUKTUR REPOSITORI
- [x] Inisialisasi direktori proyek monorepo: `mobile/` (Flutter) dan `admin/` (React + Vite + Tailwind CSS).
- [x] Inisialisasi proyek Flutter dengan dukungan Android & iOS.
- [x] Inisialisasi proyek React dengan Vite, Tailwind CSS, Lucide Icons, dan React-Leaflet.
- [x] Konfigurasi file environment `.env.example` untuk Firebase dan API eksternal.
- [x] Setup Git hooks dan standarisasi format kode (*linter*).

---

### FASE 2: DASHBOARD WEB ADMIN (REACT + VITE + TAILWIND CSS)
- [x] Setup navigasi React Router DOM (`/`, `/kyc`, `/live-map`, `/tukang`, `/users`, `/tickets`, `/withdrawals`).
- [x] Setup integrasi Firebase Web SDK (Firestore, Auth, Storage).
- [x] **Modul Verifikasi KTP (KYC):**
  - [x] Tabel antrean tukang berstatus `pending_verification`.
  - [x] Modal preview foto KTP resolusi tinggi dengan zoom.
  - [x] Tombol **Approve** (ubah status jadi `verified`) dan **Reject** (isi alasan).
- [x] **Modul Lacak Posisi Tukang (Live Map):**
  - [x] Integrasi React-Leaflet dengan OpenStreetMap tiles.
  - [x] Marker real-time posisi tukang berdasarkan koordinat `currentLocation`.
  - [x] Tooltip detail status tukang (Online/Menuju Lokasi/Bekerja).
- [x] **Modul Manajemen Mitra & Fitur Suspend 3 Hari:**
  - [x] Tabel data tukang lengkap (Rating, Total Order, Status).
  - [x] Dialog form Suspend 3 Hari: input alasan, update `isSuspended: true` dan `suspendedUntil: now + 72 jam`.
  - [x] Tombol Cabut Suspend (*Unsuspend*).
- [x] **Modul Monitoring Tiket & Approval Tarik Dana:**
  - [x] Feed pantau tiket aktif beserta foto keluhan dan foto before/after.
  - [x] Tabel permintaan penarikan saldo dompet mitra + aksi konfirmasi transfer.

---

### FASE 3: MOBILE FLUTTER CORE & AUTENTIKASI
- [x] Setup struktur Clean Architecture di Flutter (Core, Data, Domain, Presentation, BLoC).
- [x] Setup dependency injection (`get_it` / repository provider).
- [x] Implementasi Autentikasi Firebase:
  - [x] Login & Registrasi manual dengan Email & Password.
  - [x] Login instan via Google Sign-In.
- [x] **Onboarding & Registrasi Mitra Tukang:**
  - [x] Form biodata: Nama lengkap, tanggal lahir, umur otomatis.
  - [x] Form keahlian: Multi-select 10 kategori (AC, Cleaning, Las, Bangunan, Plumbing, dll.).
  - [x] Form metode pencairan dana: Bank (BCA, BRI, BNI, Mandiri) & E-Wallet (DANA, GoPay, OVO, ShopeePay).
  - [x] Fitur ambil/unggah foto KTP ke Firebase Storage.
  - [x] Layar tunggu konfirmasi verifikasi admin.

---

### FASE 4: ORDER MATCHING & BIDDING SYSTEM
- [ ] **Fitur User:**
  - [ ] Form posting tiket keluhan (Pilih kategori, deskripsi, upload foto keluhan).
  - [ ] Integrasi mini map Leaflet untuk pinpoint alamat rumah.
  - [ ] Layar memantau penawaran masuk dari mitra tukang secara real-time.
  - [ ] Fitur **Lock Tukang** untuk memilih salah satu penawaran terbaik.
- [ ] **Fitur Mitra Tukang:**
  - [ ] Radar tiket masuk berdasarkan kategori layanan yang dikuasai tukang.
  - [ ] Modal input estimasi biaya & pesan penawaran (*bidding*).
  - [ ] Pencegahan aksi: Tukang yang sedang dalam status **Suspend** dilarang mengajukan bid dan melihat banner countdown sanksi.

---

### FASE 5: SIKLUS PENGERJAAN & PELACAKAN GPS REALTIME
- [ ] **Aturan Pembatalan:**
  - [ ] Tombol batal aktif untuk User sebelum tukang berstatus *"Menuju Lokasi"*.
  - [ ] Tombol batal otomatis terkunci begitu status menjadi *"Menuju Lokasi"*.
- [ ] **Pelacakan Live GPS:**
  - [ ] Background service pada HP tukang mengirim koordinat GPS setiap 8-10 detik.
  - [ ] User App menampilkan marker tukang yang bergerak menuju rumah user di atas peta OpenStreetMap.
- [ ] **Inspeksi di Tempat & Rincian Biaya:**
  - [ ] Tukang tiba di lokasi $\rightarrow$ Input rincian biaya final (Jasa + Suku cadang).
  - [ ] Notifikasi pop-up ke User App untuk menyetujui rincian biaya tersebut.
- [ ] **Dokumentasi Bukti Kerja:**
  - [ ] Tukang wajib memotret dan mengunggah foto **Sebelum Pengerjaan** sebelum tombol mulai aktif.
  - [ ] Tukang wajib memotret dan mengunggah foto **Setelah Pengerjaan** sebelum pekerjaan ditutup.

---

### FASE 6: IN-APP CHAT REALTIME
- [ ] Pembuatan sub-koleksi `tickets/{ticketId}/chats` di Firestore.
- [ ] Tampilan antarmuka obrolan (*Chat UI*) dengan bubble pesan pengguna dan mitra.
- [ ] Fitur pengiriman pesan teks real-time dengan status terkirim/terbaca.
- [ ] Fitur pengiriman foto langsung dari kamera/galeri ke ruang chat.
- [ ] Privasi nomor telepon: Nomor HP tidak ditampilkan pada profil obrolan.

---

### FASE 7: PAYMENT GATEWAY DOKU & IN-APP WALLET
- [ ] Setup Firebase Cloud Functions untuk backend payment.
- [ ] Endpoint `/createPayment` untuk membuat transaksi DOKU (VA BCA/BRI/BNI/Mandiri & QRIS/E-Wallet).
- [ ] Endpoint Webhook `/dokuPaymentWebhook`:
  - [ ] Verifikasi HMAC signature DOKU.
  - [ ] Update status tiket menjadi `paid`.
  - [ ] Penambahan saldo ke dompet digital mitra tukang (**0% komisi platform** pada tahap awal).
- [ ] Opsi Pembayaran Tunai (Cash) dengan konfirmasi dari kedua belah pihak.
- [ ] **Dompet Mitra (Wallet):**
  - [ ] Tampilan saldo aktif dan riwayat pemasukan.
  - [ ] Form permohonan Tarik Dana (*Withdraw*) ke rekening bank/e-wallet terdaftar.
- [ ] Fitur Rating & Review bintang 1 - 5 dari User setelah pembayaran selesai.

---

### FASE 8: PENGUJIAN, KEAMANAN, & PELUNCURAN
- [ ] Deploy Firebase Security Rules (`firestore.rules` dan `storage.rules`).
- [ ] Pengujian skenario edge-case:
  - [ ] Tukang mencoba bid saat sedang disuspend $\rightarrow$ Harus tertolak.
  - [ ] User mencoba membatalkan saat tukang sudah menuju lokasi $\rightarrow$ Tombol nonaktif.
  - [ ] Pembayaran DOKU simulasi sukses di Sandbox $\rightarrow$ Saldo dompet tukang bertambah otomatis.
- [ ] Build & Test Flutter APK untuk Android dan Runner untuk iOS.
- [ ] Build & Deploy Web Admin ke Firebase Hosting / Vercel.
