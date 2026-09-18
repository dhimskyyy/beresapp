# SYSTEM & CODEBASE ARCHITECTURE (architecture.md)

Dokumen ini mendefinisikan arsitektur teknis menyeluruh, arsitektur kode aplikasi mobile Flutter (*Clean Architecture with BLoC*), struktur dashboard Web Admin React, dan tata kelola konfigurasi lingkungan untuk proyek **Beres**.

---

## 1. ARSITEKTUR TINGKAT TINGGI (*HIGH-LEVEL ARCHITECTURE*)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           CLIENT APPLICATIONS                           │
│                                                                         │
│   ┌───────────────────────────┐         ┌───────────────────────────┐   │
│   │   Beres User (Flutter)    │         │   Beres Mitra (Flutter)   │   │
│   │   - Pencari Jasa Tukang   │         │   - Penyedia Jasa Mitra   │   │
│   └─────────────┬─────────────┘         └─────────────┬─────────────┘   │
│                 │                                     │                 │
│                 └──────────────────┬──────────────────┘                 │
│                                    │                                    │
│                 ┌──────────────────┴──────────────────┐                 │
│                 │    Beres Web Admin (React + Vite)   │                 │
│                 │    - KYC, Lacak GPS, Suspend 3 Hari │                 │
│                 └──────────────────┬──────────────────┘                 │
└────────────────────────────────────┼────────────────────────────────────┘
                                     │ HTTPS / WSS / gRPC
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         FIREBASE CLOUD PLATFORM                         │
│                                                                         │
│   ┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────┐   │
│   │    Firebase Auth    │   │   Cloud Firestore   │   │   Cloud     │   │
│   │  (Email & Google)   │   │ (Realtime Database) │   │   Storage   │   │
│   └─────────────────────┘   └──────────┬──────────┘   └─────────────┘   │
│                                        │                                │
│   ┌────────────────────────────────────┴────────────────────────────┐   │
│   │                    Firebase Cloud Functions                     │   │
│   │    - Webhook Verifikasi Pembayaran DOKU                         │   │
│   │    - Push Notification FCM Dispatcher                           │   │
│   │    - Scheduled Tasks (Cek Masa Expire Suspend 3 Hari)           │   │
│   └────────────────────────────────────┬────────────────────────────┘   │
└────────────────────────────────────────┼────────────────────────────────┘
                                         │
                                         ▼
                   ┌───────────────────────────────────────────┐
                   │           EXTERNAL INTEGRATIONS           │
                   │  - DOKU Checkout & Payment API Gateway    │
                   │  - OpenStreetMap Tiles & Nominatim API    │
                   └───────────────────────────────────────────┘
```

---

## 2. ARSITEKTUR FLUTTER MOBILE (CLEAN ARCHITECTURE + BLOC)

Aplikasi mobile dibangun dengan prinsip **Clean Architecture** yang memisahkan tanggung jawab kode menjadi tiga lapisan utama: **Presentation**, **Domain**, dan **Data**, dengan **BLoC / Cubit** sebagai pengelola state reaktif.

### 2.1. Diagram Lapisan Kode (Layered Architecture)
```
┌────────────────────────────────────────────────────────────────────────┐
│                          PRESENTATION LAYER                            │
│   - UI Pages & Screens                                                 │
│   - Reusable Custom Widgets (Button, Input, MapView, Cards)            │
│   - BLoC / Cubits (Menangkap Event UI, Mengeluarkan State)             │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Memanggil
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                             DOMAIN LAYER                               │
│   - Entities (Objek bisnis murni: Ticket, UserProfile, TukangProfile)   │
│   - Use Cases (Logika bisnis: SubmitBid, LockTukang, UploadWorkProof)   │
│   - Repository Interfaces (Kontrak abstrak tanpa tahu sumber data)     │
└───────────────────────────────────▲────────────────────────────────────┘
                                    │ Diimplementasikan oleh
                                    │
┌───────────────────────────────────┴────────────────────────────────────┐
│                              DATA LAYER                                │
│   - Models (Serialisasi JSON / Firestore Document Converter)           │
│   - Data Sources (FirestoreService, FirebaseAuthService, StorageService)│
│   - Repository Implementations (TicketRepoImpl, TukangRepoImpl)        │
└────────────────────────────────────────────────────────────────────────┘
```

### 2.2. Struktur Folder Flutter (`mobile/`)
```
mobile/
├── android/
├── ios/
├── assets/
│   ├── icons/
│   ├── images/
│   └── fonts/
├── lib/
│   ├── core/
│   │   ├── constants/            # AppColors, AppTextStyles, AppStrings
│   │   ├── network/              # Firebase Client & HTTP Helpers
│   │   ├── theme/                # Light Theme Data
│   │   ├── utils/                # DateFormatter, CurrencyFormatter, Haversine
│   │   └── widgets/              # PrimaryButton, CustomTextField, ShimmerLoading
│   │
│   ├── data/
│   │   ├── datasources/          # AuthRemoteSource, TicketRemoteSource, ChatRemoteSource
│   │   ├── models/               # UserModel, TukangModel, TicketModel, ChatMessageModel
│   │   └── repositories/         # Implementasi konkret dari domain repository
│   │
│   ├── domain/
│   │   ├── entities/             # User, Tukang, Ticket, Bid, ChatMessage
│   │   ├── repositories/         # IAuthRepository, ITicketRepository, ITukangRepository
│   │   └── usecases/             # CreateTicketUseCase, SubmitBidUseCase, UpdateJobStatusUseCase
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── bloc/             # AuthBloc, AuthEvent, AuthState
│   │   │   └── pages/            # LoginPage, RegisterUserPage, RegisterMitraPage
│   │   ├── user/
│   │   │   ├── bloc/             # UserHomeBloc, TicketCreationBloc, OrderTrackingBloc
│   │   │   └── pages/            # UserHomePage, CreateTicketPage, OffersListPage, TrackingPage
│   │   ├── tukang/
│   │   │   ├── bloc/             # MitraJobFeedBloc, ActiveJobBloc, WalletBloc
│   │   │   └── pages/            # MitraHomePage, KycUploadPage, ActiveJobStepPage, WalletPage
│   │   └── chat/
│   │       ├── bloc/             # ChatBloc, ChatEvent, ChatState
│   │       └── pages/            # ChatDetailPage
│   │
│   ├── app_user.dart             # Root MaterialApp untuk Beres User
│   ├── app_mitra.dart            # Root MaterialApp untuk Beres Mitra
│   ├── main_user.dart            # Entry point khusus binary Beres User
│   └── main_mitra.dart           # Entry point khusus binary Beres Mitra
├── pubspec.yaml
└── README.md
```

### 2.3. Pendekatan Dual Entry Point (Single Codebase, Two Apps)
Untuk menjaga ukuran aplikasi tetap ramping dan pengalaman pengguna tetap fokus, satu codebase Flutter ini dapat dikompilasi menjadi dua aplikasi berbeda menggunakan entry point terpisah:
* **Jalankan Aplikasi User:**
  ```bash
  flutter run -t lib/main_user.dart
  ```
* **Jalankan Aplikasi Mitra Tukang:**
  ```bash
  flutter run -t lib/main_mitra.dart
  ```

---

## 3. ARSITEKTUR WEB ADMIN (REACT + VITE + TAILWIND CSS)

Dashboard Web Admin dirancang dengan konsep *Single Page Application (SPA)* berbasis React 18, Vite sebagai *build tool* kilat, dan Tailwind CSS untuk antarmuka yang bersih dan modern.

### 3.1. Struktur Folder Web Admin (`admin/`)
```
admin/
├── public/
│   └── favicon.ico
├── src/
│   ├── assets/                   # Logo Beres & grafis ilustrasi
│   ├── components/
│   │   ├── layout/               # Sidebar, Header, AdminLayout
│   │   ├── common/               # Table, Badge, Button, Modal, StatCard
│   │   ├── kyc/                  # KycDetailModal, ZoomableKtpViewer
│   │   ├── map/                  # TukangLiveMap (React-Leaflet), TukangMarker
│   │   └── suspend/              # SuspendDialog (Form Alasan & Timer 3 Hari)
│   ├── context/
│   │   └── AuthContext.jsx       # State session login Admin
│   ├── hooks/
│   │   ├── useTukangList.js      # Realtime hook listener tukang dari Firestore
│   │   ├── useTicketList.js      # Realtime hook listener tiket aktif
│   │   └── useWithdrawals.js     # Hook listener permintaan tarik dana
│   ├── pages/
│   │   ├── DashboardPage.jsx     # Statistik omset, total order, total mitra
│   │   ├── KycApprovalPage.jsx   # Verifikasi KTP baru
│   │   ├── TukangMapPage.jsx     # Peta layar penuh posisi GPS tukang live
│   │   ├── TukangListPage.jsx    # Manajemen tukang & tombol Suspend 3 Hari
│   │   ├── UserListPage.jsx      # Direktori data pengguna
│   │   ├── TicketMonitorPage.jsx # Pantau status tiket, foto before & after
│   │   └── WithdrawalPage.jsx    # Approval pencairan dana dompet mitra
│   ├── services/
│   │   ├── firebase.js           # Inisialisasi Firebase SDK Client
│   │   └── adminApi.js           # Method update verifikasi, suspend, dan approve dana
│   ├── App.jsx                   # Konfigurasi React Router DOM
│   ├── main.jsx                  # Entry point React
│   └── index.css                 # Tailwind directives & custom styles
├── package.json
├── tailwind.config.js
└── vite.config.js
```

---

## 4. LOGIKA INTEGRITAS SANKSI SUSPEND TUKANG (3 HARI)

Untuk memastikan sanksi suspend berjalan tanpa celah:
1. **Pemicu di Web Admin:**
   Admin memilih tukang dan menekan tombol *"Suspend 3 Hari"*, lalu mengisi alasan sanksi.
   ```javascript
   // Firestore update di adminApi.js
   const threeDaysInMs = 3 * 24 * 60 * 60 * 1000;
   await updateDoc(doc(db, "tukang", tukangId), {
     isSuspended: true,
     suspendedUntil: Timestamp.fromMillis(Date.now() + threeDaysInMs),
     suspendReason: reason,
     isOnline: false // Otomatis dipaksa offline
   });
   ```
2. **Validasi di Mobile Mitra (Beres Mitra):**
   * Saat aplikasi terbuka, BLoC memeriksa:
     $$\text{isBlocked} = (\text{isSuspended} == \text{true}) \land (\text{suspendedUntil} > \text{now})$$
   * Jika diblokir:
     * Tombol "Online" dinonaktifkan.
     * Tombol "Ajukan Penawaran" pada tiket disembunyikan.
     * Muncul banner merah dengan countdown sisa waktu suspensi.
3. **Validasi di Firestore Security Rules:**
   Rules database memblokir pengajuan bid tiket jika `isSuspended == true` meskipun ada upaya manipulasi lewat API.

---

## 5. STRATEGI ERROR HANDLING & LOGGING

1. **Global Error Boundary (Web Admin):** Menangkap unhandled exception komponen dan menampilkan UI fallback ramah pengguna.
2. **BLoC Exception Mapping (Flutter):** Mengubah Firebase error code (seperti `auth/user-not-found`, `permission-denied`) menjadi teks bahasa Indonesia yang jelas bagi pengguna awam.
3. **Network Reconnection:** Menggunakan kemampuan offline cache bawaan Cloud Firestore sehingga pengguna tidak langsung mendapatkan error layar putih saat sinyal internet melemah.
