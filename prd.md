# PRODUCT REQUIREMENT DOCUMENT (PRD)

---

## 1. INFORMASI PROYEK
* **Nama Produk:** Beres (Beres App, Beres Mitra, & Beres Admin)
* **Kategori:** On-Demand Handyman & Home Services Platform
* **Platform Target:** 
  * Mobile: Android & iOS (Flutter)
  * Web Admin: Desktop Browser (React + Vite + Tailwind CSS)
* **Backend:** Firebase Suite (Auth, Firestore, Storage, Cloud Functions)
* **Payment Gateway:** DOKU (Virtual Account, QRIS, E-Wallet) + In-App Wallet + Cash
* **Layanan Peta:** OpenStreetMap / Leaflet (100% Bebas Biaya API Key)

---

## 2. LATAR BELAKANG & VISI PRODUK
Mencari tukang terpercaya untuk perbaikan rumah tangga (AC bocor, pipa mampet, kelistrikan, las, renovasi) di Indonesia kerap kali memakan waktu, memiliki tarif yang tidak transparan, dan minim jaminan keamanan. 

**Beres** hadir sebagai platform on-demand yang mempertemukan pengguna (*User*) dengan penyedia jasa terverifikasi (*Mitra Tukang*). Dengan model **Open Bidding**, pengguna mendapatkan penawaran harga terbaik, transparansi pekerjaan melalui **foto sebelum dan sesudah pengerjaan**, pelacakan lokasi tukang secara **realtime di peta**, serta transaksi aman menggunakan sistem **In-App Wallet & Payment Gateway DOKU**.

---

## 3. PENGGUNA & PERAN (*ROLES & PERSONAS*)

| Peran | Deskripsi | Akses Platform |
| :--- | :--- | :--- |
| **User (Pelanggan)** | Individu yang membutuhkan jasa perbaikan/instalasi rumah tangga atau kendaraan. | Beres User App (Mobile) |
| **Mitra Tukang** | Tenaga ahli/pekerja lepas yang mencari order pekerjaan sesuai keahlian teknisnya. | Beres Mitra App (Mobile) |
| **Super Admin** | Pengelola ekosistem Beres yang memverifikasi KTP tukang, memantau operasional, mendisiplinkan mitra (suspend), dan mengelola pencairan dana. | Beres Web Admin (Web Desktop) |

---

## 4. KATEGORI LAYANAN (*SERVICES*)
Mitra Tukang dapat memilih satu atau lebih keahlian berikut saat registrasi:
1. **AC:** Cuci AC, perbaikan kompresor, instalasi baru, isi freon.
2. **Cleaning:** Pembersihan menyeluruh rumah, sedot debu/tungau, cuci toren air.
3. **Elektronik:** Servis mesin cuci, kulkas, TV, microwave, dispenser.
4. **Las:** Pembuatan dan servis pagar, kanopi, teralis, gerbang.
5. **Bangunan:** Cat dinding, pasang keramik, renovasi ruangan, atap bocor.
6. **Besi & Baja:** Pemasangan rangka baja ringan, kanopi baja ringan, konstruksi besi.
7. **Bengkel Motor:** Servis berkala panggilan, tambal/ganti ban darurat, aki drop.
8. **Bengkel Mobil:** Servis panggilan darurat, jumper aki, ganti ban cadangan, tune-up ringan.
9. **Pengrajin Kayu:** Pembuatan kitchen set, reparasi mebel, kusen, pintu, lemari.
10. **Plumbing (Pipa & Air):** Pipa bocor/mampet, instalasi pipa baru, servis pompa air, kran rusak.

---

## 5. SPESIFIKASI FITUR DETAIL

### 5.1. Aplikasi User (Beres App)
1. **Autentikasi:**
   * Registrasi & Login manual via Email dan Kata Sandi.
   * One-Tap Login via Google (Gmail).
   * Reset password melalui tautan email.
2. **Posting Tiket Keluhan (Buat Order):**
   * Pemilihan kategori layanan (misal: AC).
   * Input judul keluhan dan deskripsi detail masalah.
   * Lampiran foto keluhan (maksimal 5 foto).
   * Pinpoint lokasi alamat penjemputan/rumah pada OpenStreetMap.
   * Pengaturan preferensi jadwal (Sekarang / Terjadwal).
3. **Pusat Penawaran & Lock Tukang:**
   * Notifikasi real-time saat ada tukang mengajukan penawaran (*bid*).
   * Melihat profil tukang penawar: Nama, Foto, Rating Bintang (1-5), Ulasan sebelumnya, dan Estimasi Biaya.
   * Tombol **"Lock Tukang"** untuk memilih tukang yang disetujui.
4. **Pembatalan Order:**
   * User dapat membatalkan order secara gratis selama status tukang belum *"Menuju Lokasi"*.
   * Tombol batal otomatis terkunci begitu tukang berstatus *"Menuju Lokasi"*.
5. **Live Tracking & Chat:**
   * Pelacakan koordinat GPS tukang saat status *"Menuju Lokasi"* secara live di peta OpenStreetMap.
   * Chat in-app real-time (hanya teks dan foto, tanpa mengekspos nomor telepon).
6. **Persetujuan Rincian Biaya Final:**
   * Tukang tiba di lokasi dan memeriksa masalah langsung.
   * User menerima pop-up konfirmasi rincian biaya final (jasa + sparepart) yang diinput tukang.
   * User menekan tombol **"Setujui Rincian Biaya"** sebelum pengerjaan dimulai.
7. **Inspeksi Hasil Kerja & Pembayaran:**
   * Meninjau foto **Sebelum Pengerjaan** dan foto **Setelah Pengerjaan** yang diunggah tukang.
   * Memilih metode pembayaran:
     * **Non-Tunai via DOKU:** Virtual Account (BCA, BRI, BNI, Mandiri) atau QRIS / E-Wallet (DANA, GoPay, OVO, ShopeePay).
     * **Tunai (Cash):** Pembayaran langsung ke tukang.
8. **Rating & Ulasan:**
   * Memberikan rating bintang (1 - 5) dan komentar ulasan setelah pembayaran lunas.

---

### 5.2. Aplikasi Mitra Tukang (Beres Mitra)
1. **Onboarding & Registrasi Mitra:**
   * Input nama lengkap, tanggal lahir, usia, nomor telepon aktif.
   * Multi-select kategori layanan yang dikuasai (10 kategori).
   * Pendaftaran metode pencairan dana (*payout accounts*):
     * Rekening Bank: BCA, BRI, BNI, Mandiri (input nomor rekening dan nama pemilik).
     * E-Wallet: DANA, GoPay, OVO, ShopeePay (input nomor HP terdaftar).
   * Unggah foto KTP asli (Status akun: `pending_verification`).
2. **Job Feed & Bidding Tiket:**
   * Menerima notifikasi push saat tiket baru dibuat sesuai kategori keahlian di radius terdekat.
   * Input estimasi biaya dan pesan pengantar (*bidding proposal*).
   * Peringatan larangan bidding jika akun sedang dalam masa **Suspend**.
3. **Workflow Pelaksanaan Kerja (State Machine):**
   * **Accept & Lock:** Menerima notifikasi bahwa User telah melakukan "Lock Tukang".
   * **Update "Menuju Lokasi":** Aplikasi mulai mentransmisikan koordinat GPS secara berkala ke Firestore.
   * **Tiba di Lokasi & Diagnosa:** Input rincian biaya aktual (Jasa + Suku Cadang).
   * **Foto Sebelum (Before):** Wajib unggah foto kondisi sebelum diperbaiki.
   * **Mulai Bekerja:** Status beralih ke `IN_PROGRESS`.
   * **Foto Sesudah (After):** Wajib unggah foto hasil perbaikan.
   * **Konfirmasi Selesai:** Menunggu User menyelesaikan pembayaran.
4. **Dompet Mitra (In-App Wallet) & Tarik Dana:**
   * Saldo bertambah otomatis saat transaksi DOKU diselesaikan user.
   * Riwayat pemasukan dan riwayat penarikan dana.
   * Tombol **"Tarik Dana" (Withdraw)** ke rekening bank atau e-wallet yang telah didaftarkan.
5. **Penalti & Status Suspend:**
   * Tampilan banner peringatan jika admin mengenakan suspend (contoh: *"Akun Anda disuspend selama 3 hari karena pelanggaran: [Alasan]"*).
   * Tombol ambil order otomatis dinonaktifkan hingga masa suspend berakhir.

---

### 5.3. Web Admin Dashboard (React + Vite + Tailwind CSS)
1. **Verifikasi KTP Mitra (KYC Management):**
   * Filter daftar mitra: *Pending*, *Verified*, *Rejected*.
   * Modal inspeksi: Foto KTP resolusi tinggi, data tanggal lahir, keahlian, nomor rekening/e-wallet.
   * Aksi: **Setujui (Approve)** atau **Tolak (Reject)** disertai catatan alasan.
2. **Lacak Posisi Tukang (Real-time GPS Tracking Map):**
   * Peta layar penuh (OpenStreetMap / Leaflet) dengan marker lokasi live seluruh mitra.
   * Filter status: *Sedang Menganggur (Online)*, *Menuju Lokasi*, *Sedang Bekerja*, *Offline*.
   * Klik marker untuk melihat info cepat (Nama, rating, kategori, order aktif).
3. **Manajemen Pengguna & Mitra (User & Tukang Directory):**
   * Tabel daftar seluruh User: nama, email, jumlah transaksi, status aktif.
   * Tabel daftar seluruh Tukang: nama, keahlian, rating bintang, saldo dompet, status verifikasi.
4. **Fitur Suspend Mitra (3 Hari):**
   * Tombol aksi **"Suspend 3 Hari"** pada profil tukang.
   * Form input alasan suspensi (misal: *Datang tidak tepat waktu / meminta biaya di luar kesepakatan*).
   * Sistem otomatis menghitung `suspendedUntil = waktu_sekarang + 72 jam`.
   * Opsi cabut suspensi lebih awal (*Unsuspend*) jika ada banding yang diterima.
5. **Pusat Monitoring Tiket Pekerjaan:**
   * Pemantauan tiket aktif secara live: foto keluhan, rincian biaya, foto sebelum & sesudah pengerjaan.
   * Catatan log pembatalan tiket.
6. **Manajemen Penarikan Dana (Withdrawal Approvals):**
   * Antrean permintaan pencairan dana dari dompet tukang.
   * Konfirmasi transfer manual/otomatis ke rekening BCA/Mandiri/BRI/BNI/E-Wallet mitra.

---

## 6. SIKLUS HIDUP ORDER (*ORDER STATE MACHINE*)

```
[1. OPEN]
   User memposting tiket keluhan
   │
   ▼
[2. BIDDING]
   Tukang terdekat mengajukan estimasi biaya
   │
   ▼
[3. LOCKED]
   User mengunci satu tukang (User masih bisa batal gratis)
   │
   ▼
[4. ON_THE_WAY]
   Tukang update status "Menuju Lokasi" (Live GPS aktif, tombol batal terkunci)
   │
   ▼
[5. ARRIVED_INSPECTING]
   Tukang tiba di rumah user, diagnosa kerusakan, input tagihan final
   │
   ▼
[6. IN_PROGRESS]
   Tukang upload foto "Sebelum", pengerjaan fisik dimulai
   │
   ▼
[7. WORK_COMPLETED]
   Tukang upload foto "Sesudah", pekerjaan tuntas
   │
   ▼
[8. PAYMENT_PENDING]
   User membayar via DOKU (VA/QRIS) atau Cash
   │
   ▼
[9. COMPLETED]
   Uang masuk ke wallet tukang, user memberi rating bintang 1-5
```

---

## 7. ATURAN BISNIS KHUSUS (*BUSINESS RULES*)

1. **Aturan Pembatalan Pasca-Lock:**
   * Selama tukang belum menekan *"Menuju Lokasi"*, User dapat membatalkan pesanan secara mandiri.
   * Setelah tukang menekan *"Menuju Lokasi"*, User maupun Tukang tidak dapat membatalkan melalui aplikasi secara sepihak.
   * Jika pembatalan terpaksa dilakukan setelah tukang sampai di lokasi, pembatalan hanya dapat dieksekusi oleh Tukang setelah bersepakat dengan User. User wajib membayar uang ganti bensin/transport secara tunai di luar aplikasi. Tiket kemudian dinyatakan hangus (*Canceled*).
2. **Skema Monetisasi:**
   * **0% Potongan Komisi** pada fase peluncuran awal. Seluruh pembayaran jasa masuk utuh 100% ke dompet mitra tukang.
3. **Privasi Komunikasi:**
   * Obrolan hanya dilakukan melalui fitur Chat in-app. Nomor telepon pribadi disembunyikan untuk menjaga keamanan dan mencegah transaksi gelap di luar sistem.

---

## 8. SKEMA STRUKTUR DATABASE (CLOUDFIRESTORE)

### 8.1. Koleksi `users`
```json
{
  "id": "USR1001",
  "name": "Budi Santoso",
  "email": "budi@gmail.com",
  "phone": "081234567890",
  "photoUrl": "https://storage.googleapis.com/.../profile.jpg",
  "role": "user",
  "createdAt": "2026-09-18T08:00:00Z"
}
```

### 8.2. Koleksi `tukang`
```json
{
  "id": "TKG2001",
  "name": "Ahmad Subarjo",
  "email": "ahmad@gmail.com",
  "phone": "081398765432",
  "photoUrl": "https://storage.googleapis.com/.../tkg.jpg",
  "birthDate": "1988-04-12",
  "age": 38,
  "services": ["ac", "elektronik", "plumbing"],
  "payoutAccounts": [
    { "type": "bank", "provider": "BCA", "accountNumber": "210219876", "accountName": "Ahmad Subarjo" },
    { "type": "ewallet", "provider": "DANA", "accountNumber": "081398765432", "accountName": "Ahmad Subarjo" }
  ],
  "ktpUrl": "https://storage.googleapis.com/.../ktp_ahmad.jpg",
  "verificationStatus": "verified",
  "rejectionReason": null,
  "isSuspended": false,
  "suspendedUntil": null,
  "suspendReason": null,
  "walletBalance": 450000,
  "rating": 4.9,
  "reviewCount": 38,
  "currentLocation": {
    "lat": -6.2088,
    "lng": 106.8456,
    "updatedAt": "2026-09-18T08:25:00Z"
  },
  "isOnline": true,
  "createdAt": "2026-09-18T07:00:00Z"
}
```

### 8.3. Koleksi `tickets`
```json
{
  "id": "TCK9001",
  "userId": "USR1001",
  "userName": "Budi Santoso",
  "category": "ac",
  "title": "AC Kamar Tidur Bocor Menetes",
  "description": "AC 1 PK meneteskan air terus menerus dan kurang dingin.",
  "photoUrls": ["https://storage.../ac1.jpg"],
  "address": "Jl. Mawar No. 12, Kebayoran Baru, Jakarta Selatan",
  "location": { "lat": -6.2382, "lng": 106.8123 },
  "status": "LOCKED",
  "selectedTukangId": "TKG2001",
  "bids": [
    {
      "tukangId": "TKG2001",
      "tukangName": "Ahmad Subarjo",
      "tukangRating": 4.9,
      "estimatedPrice": 150000,
      "note": "Kemungkinan saluran pembuangan tersumbat lumut. Siap datang 20 menit.",
      "createdAt": "2026-09-18T08:10:00Z"
    }
  ],
  "finalBill": {
    "items": [
      { "title": "Cuci Servis AC 1 PK", "amount": 75000 },
      { "title": "Pembersihan Saluran Pipa Pembuangan", "amount": 50000 }
    ],
    "totalAmount": 125000,
    "approvedByUser": true
  },
  "beforePhotos": ["https://storage.../before.jpg"],
  "afterPhotos": ["https://storage.../after.jpg"],
  "paymentMethod": "doku",
  "paymentStatus": "paid",
  "dokuInvoiceId": "INV-DOKU-892182",
  "rating": {
    "stars": 5,
    "review": "Kerja cepat, bersih, dan AC langsung dingin kembali.",
    "createdAt": "2026-09-18T09:30:00Z"
  },
  "cancelReason": null,
  "createdAt": "2026-09-18T08:05:00Z",
  "updatedAt": "2026-09-18T09:30:00Z"
}
```

---

## 9. NON-FUNCTIONAL REQUIREMENTS (NFR)
1. **Keamanan Data & Privasi:**
   * Foto KTP dilindungi dengan Firebase Storage Security Rules dan hanya dapat diakses oleh Admin.
   * Nomor telepon disembunyikan antar pengguna di dalam chat.
2. **Kinerja & Latensi:**
   * Pembaruan koordinat GPS Tukang dikirim setiap 5-10 detik saat status `ON_THE_WAY`.
   * Latensi chat di bawah 1 detik menggunakan Firestore Snapshot Listeners.
3. **Ketersediaan (*Reliability*):**
   * Dukungan penanganan koneksi terputus (*offline persistence*) pada Firestore.

---

## 10. TAHAPAN PENGEMBANGAN (*ROADMAP*)
* **Milestone 1:** Inisialisasi struktur repositori (`admin/` dan `mobile/`).
* **Milestone 2:** Pembuatan Web Admin Dashboard (React + Vite + Tailwind CSS) lengkap dengan KYC KTP, Map Tracker, dan Suspend 3 Hari.
* **Milestone 3:** Pembuatan Mobile Apps Flutter (Beres User & Beres Mitra) dengan arsitektur BLoC/Cubit.
* **Milestone 4:** Integrasi Firebase Auth, Firestore, Storage, & OpenStreetMap Tracking.
* **Milestone 5:** Implementasi Siklus Pengerjaan Lengkap (Bidding, Lock, Foto Before/After).
* **Milestone 6:** Integrasi Payment Gateway DOKU & In-App Wallet.
