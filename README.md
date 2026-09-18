<div align="center">

# 🛠️ Beres (Beres App, Beres Mitra & Web Admin)
### *Solusi Cepat, Pasti Beres — On-Demand Handyman & Home Services Platform*

[![Web Admin CI](https://github.com/dhimskyyy/beresapp/actions/workflows/admin-ci.yml/badge.svg)](https://github.com/dhimskyyy/beresapp/actions/workflows/admin-ci.yml)
[![Flutter Mobile CI](https://github.com/dhimskyyy/beresapp/actions/workflows/mobile-ci.yml/badge.svg)](https://github.com/dhimskyyy/beresapp/actions/workflows/mobile-ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![React](https://img.shields.io/badge/React-19-61DAFB?logo=react&logoColor=black)](https://react.dev)
[![Vite](https://img.shields.io/badge/Vite-8-646CFF?logo=vite&logoColor=white)](https://vite.dev)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-v4-38B2AC?logo=tailwind-css&logoColor=white)](https://tailwindcss.com)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![OpenStreetMap](https://img.shields.io/badge/Maps-OpenStreetMap-7EBC6F?logo=openstreetmap&logoColor=white)](https://openstreetmap.org)

</div>

---

## 📌 Ringkasan Proyek

**Beres** adalah ekosistem aplikasi penyedia jasa tukang terpercaya berbasis permintaan (*on-demand*) yang menghubungkan **Pelanggan (User)** dengan **Mitra Tukang Ahli (Mitra)** melalui sistem **Open Bidding**, pelacakan lokasi **GPS realtime (OpenStreetMap Leaflet)**, dokumentasi foto kerja sebelum & sesudah, serta pembayaran aman menggunakan **In-App Wallet & Payment Gateway DOKU**.

Seluruh ekosistem dikelola dan diawasi melalui **Dashboard Web Admin** modern yang dilengkapi fitur inspeksi verifikasi KTP, radar posisi tukang, dan penegakan sanksi suspensi mitra.

---

## 🧭 10 Kategori Layanan Spesifik

| Kategori | Deskripsi Pekerjaan |
| :--- | :--- |
| ❄️ **AC** | Cuci AC, perbaikan kompresor, instalasi baru, isi freon. |
| 🧹 **Cleaning** | Pembersihan rumah menyeluruh, sedot tungau, cuci toren air. |
| 📺 **Elektronik** | Servis mesin cuci, kulkas, TV, dispenser, microwave. |
| 🔥 **Las** | Pembuatan dan perbaikan pagar, kanopi, teralis, gerbang besi. |
| 🧱 **Bangunan** | Cat dinding, pasang keramik, renovasi ruangan, atap bocor. |
| 🛡️ **Besi & Baja** | Rangka atap baja ringan, kanopi spandek, konstruksi baja. |
| 🏍️ **Bengkel Motor** | Servis panggilan, ganti/tambal ban darurat, jumper aki motor. |
| 🚗 **Bengkel Mobil** | Servis darurat, jumper aki mobil, ganti ban cadangan, tune-up ringan. |
| 🪚 **Pengrajin Kayu** | Pembuatan kitchen set, servis lemari, mebel, kusen, pintu kayu. |
| 🚿 **Plumbing** | Pipa mampet, pipa bocor, instalasi pipa baru, servis pompa air. |

---

## 🏢 Struktur Repositori Monorepo

```
beresapp/
├── .github/workflows/       # Otomasi CI/CD GitHub Actions
│   ├── admin-ci.yml         # Linting & Build Verification Web Admin
│   └── mobile-ci.yml        # Analyze & Unit Test Flutter Mobile
│
├── admin/                   # Dashboard Web Admin (React 19 + Vite + Tailwind CSS v4)
│   ├── src/
│   │   ├── components/      # Sidebar, Header, AdminLayout, Modal
│   │   ├── context/         # AdminDataContext (KYC, Suspend 3 Hari, Withdrawals)
│   │   ├── pages/           # Dashboard, KycApproval, TukangMap, TukangList, UserList, Tickets, Withdrawals
│   │   └── data/            # Realistic Mock Data & LocalStorage fallback
│   └── package.json
│
├── mobile/                  # Aplikasi Mobile Android & iOS (Flutter BLoC Clean Architecture)
│   ├── lib/
│   │   ├── core/            # Constants (AppColors, ServiceCategories), Utils
│   │   ├── data/            # Models (UserModel, TukangModel, TicketModel, ChatMessageModel)
│   │   ├── domain/          # Entities & State Machine (TicketStatus)
│   │   └── features/        # Auth, User, Tukang, Chat
│   └── pubspec.yaml
│
├── prd.md                   # Product Requirement Document
├── design.md                # UI/UX Design System & Screen Specifications
├── database_schema.md       # Firestore NoSQL Schema & Security Rules
├── api_and_integration.md   # DOKU Payment Gateway, FCM, & OpenStreetMap Protocol
├── architecture.md          # Clean Architecture & Codebase Guidelines
├── roadmap.md               # Roadmap Pengembangan 8 Fase & Checklist
└── .env.example             # Template Environment Variables
```

---

## ⚡ Fitur Unggulan Sistem

### 1. Web Admin Dashboard (Anti-AI Slop Enterprise UI)
* **Verifikasi KTP Mitra (KYC):** Inspeksi foto KTP resolusi tinggi berdampingan dengan data registrasi, tombol *Approve* instan, atau *Reject* dengan alasan.
* **Lacak GPS Tukang di Peta Live:** Peta Leaflet/OpenStreetMap interaktif dengan marker SVG dinamis status online/jalan/bekerja dan auto-fly kamera.
* **Penegakan Sanksi Suspend 3 Hari:** Menjatuhkan sanksi suspensi 72 jam kepada mitra pelanggar (mitra terkunci dari bidding dan radar order dengan countdown).
* **Monitoring Tiket & Foto:** Pantau foto keluhan, foto sebelum (*before*), dan foto sesudah (*after*) pengerjaan.
* **Approval Pencairan Dana:** Konfirmasi mutasi penarikan saldo dompet mitra ke bank BCA/Mandiri/BRI/BNI dan e-wallet.

### 2. Aplikasi Mobile (Beres User & Beres Mitra)
* **Open Bidding System:** User posting tiket keluhan, tukang terdekat di kategori terkait mengajukan penawaran harga.
* **Dual Protection Cancel Policy:** User bisa batal gratis sebelum tukang menuju lokasi; tombol otomatis terkunci saat perjalanan; pembatalan di lokasi disertai ganti transport bensin.
* **Foto Kejujuran Pengerjaan:** Wajib unggah foto sebelum fisik dibongkar dan foto hasil akhir.
* **Pembayaran Fleksibel:** Transaksi otomatis via Payment Gateway DOKU (VA/QRIS) masuk ke dompet digital mitra, atau bayar tunai (*cash*).

---

## 🚀 Panduan Menjalankan Proyek

### 1. Web Admin Dashboard
```bash
# Masuk ke direktori admin
cd admin

# Install dependencies
npm install

# Jalankan server lokal
npm run dev
```
Buka browser di `http://localhost:5173`.

### 2. Aplikasi Mobile Flutter
```bash
# Masuk ke direktori mobile
cd mobile

# Unduh packages
flutter pub get

# Jalankan analisis statis
flutter analyze

# Jalankan aplikasi (pilih target emulator / perangkat fisik)
flutter run
```

---

## 📚 Dokumen Blueprint & Arsitektur Lengkap

Semua spesifikasi teknis telah didokumentasikan secara menyeluruh di repositori ini:
* [prd.md](prd.md) — Persyaratan produk & aturan bisnis lengkap.
* [design.md](design.md) — Sistem warna, tipografi, dan spesifikasi layar mobile/admin.
* [database_schema.md](database_schema.md) — Skema database Firestore & Security Rules.
* [api_and_integration.md](api_and_integration.md) — Spesifikasi integrasi DOKU, FCM, dan OpenStreetMap.
* [architecture.md](architecture.md) — Arsitektur BLoC Clean Architecture dan React SPA.
* [roadmap.md](roadmap.md) — Checklist tugas bertahap (Fase 1 hingga Fase 8).

---

<div align="center">
  <sub>Dibangun dengan dedikasi untuk industri jasa pertukangan Indonesia 🇮🇩</sub>
</div>
