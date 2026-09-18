# DATABASE SCHEMA & SECURITY SPECIFICATION (database_schema.md)

Dokumen ini mendefinisikan skema lengkap database NoSQL Cloud Firestore, struktur penyimpanan Cloud Storage, composite index, dan aturan keamanan (*Security Rules*) untuk ekosistem aplikasi **Beres**.

---

## 1. STRUKTUR KOLEKSI CLOUD FIRESTORE

```
firestore/
├── users/
│   └── {userId}                  # Data profil pelanggan (User)
├── tukang/
│   └── {tukangId}                # Data profil mitra tukang & verifikasi
├── tickets/
│   └── {ticketId}                # Dokumen pekerjaan / tiket keluhan
│       └── chats/
│           └── {messageId}       # Pesan obrolan realtime user & tukang
├── withdrawals/
│   └── {withdrawId}              # Permintaan penarikan saldo dompet tukang
└── system_configs/
    └── admin                     # Pengaturan admin & platform
```

---

## 2. DETAIL SKEMA DOKUMEN FIRESTORE

### 2.1. Koleksi `users`
Menyimpan informasi akun pengguna (pencari jasa).

| Field | Tipe Data | Deskripsi |
| :--- | :--- | :--- |
| `id` | `string` | User UID dari Firebase Authentication. |
| `name` | `string` | Nama lengkap pengguna. |
| `email` | `string` | Alamat email terdaftar. |
| `phone` | `string` | Nomor telepon / WhatsApp. |
| `photoUrl` | `string?` | URL foto profil dari Cloud Storage (opsional). |
| `role` | `string` | Nilai statis: `'user'`. |
| `defaultAddress` | `map?` | `{ "address": string, "lat": number, "lng": number }` |
| `createdAt` | `timestamp` | Waktu pendaftaran pertama kali. |
| `updatedAt` | `timestamp` | Waktu pembaruan profil terakhir. |

---

### 2.2. Koleksi `tukang`
Menyimpan profil lengkap tukang, dokumen KTP, status verifikasi admin, status suspensi, dan koordinat GPS.

| Field | Tipe Data | Deskripsi |
| :--- | :--- | :--- |
| `id` | `string` | UID Mitra dari Firebase Authentication. |
| `name` | `string` | Nama lengkap sesuai KTP. |
| `email` | `string` | Alamat email terdaftar. |
| `phone` | `string` | Nomor HP / WhatsApp aktif. |
| `photoUrl` | `string?` | URL foto profil pribadi tukang. |
| `birthDate` | `string` | Format: `YYYY-MM-DD` (misal: `"1990-05-14"`). |
| `age` | `number` | Usia tukang dalam tahun. |
| `services` | `array<string>` | Daftar keahlian: `["ac", "cleaning", "elektronik", "las", "bangunan", "besi_baja", "bengkel_motor", "bengkel_mobil", "pengrajin_kayu", "plumbing"]`. |
| `payoutAccounts` | `array<map>` | Daftar rekening pencairan dana: `[{ "type": "bank"|"ewallet", "provider": "BCA"|"BRI"|"BNI"|"MANDIRI"|"DANA"|"GOPAY"|"OVO"|"SHOPEEPAY", "accountNumber": "12345678", "accountName": "Budi Santoso" }]`. |
| `ktpUrl` | `string` | URL foto KTP resmi di Firebase Storage. |
| `verificationStatus` | `string` | Status KYC: `'pending_verification'`, `'verified'`, `'rejected'`. |
| `rejectionReason` | `string?` | Alasan penolakan jika KTP ditolak admin. |
| `isSuspended` | `boolean` | `true` jika sedang dikenakan hukuman penangguhan kerja. |
| `suspendedUntil` | `timestamp?` | Waktu berakhirnya masa suspend (misal: `now + 3 hari`). |
| `suspendReason` | `string?` | Alasan sanksi yang diinput oleh Admin. |
| `walletBalance` | `number` | Saldo dompet in-app (Rupiah) yang siap ditarik. |
| `rating` | `number` | Rata-rata bintang (1.0 - 5.0). Default: `5.0`. |
| `reviewCount` | `number` | Total ulasan yang diterima. |
| `isOnline` | `boolean` | Status ketersediaan untuk menerima radar order. |
| `currentJobId` | `string?` | ID tiket yang sedang dikerjakan secara aktif. |
| `currentLocation` | `map?` | `{ "lat": number, "lng": number, "heading": number, "updatedAt": timestamp }`. |
| `createdAt` | `timestamp` | Waktu akun dibuat. |

---

### 2.3. Koleksi `tickets`
Menyimpan informasi order keluhan, siklus tahapan pengerjaan (*state machine*), dan riwayat foto kerja.

| Field | Tipe Data | Deskripsi |
| :--- | :--- | :--- |
| `id` | `string` | ID Dokumen tiket unik. |
| `userId` | `string` | ID Pengguna pembuat tiket. |
| `userName` | `string` | Nama Pengguna. |
| `userPhone` | `string` | Nomor kontak pengguna (hanya untuk log sistem). |
| `category` | `string` | Kategori masalah (misal: `'ac'`, `'plumbing'`). |
| `title` | `string` | Judul keluhan singkat. |
| `description` | `string` | Deskripsi detail kerusakan/masalah. |
| `photoUrls` | `array<string>` | Foto awal keluhan dari user (1 - 5 foto). |
| `address` | `string` | Alamat lengkap rumah/lokasi kerja. |
| `location` | `map` | Koordinat penjemputan: `{ "lat": number, "lng": number }`. |
| `status` | `string` | Status tahapan order: `'OPEN'`, `'BIDDING'`, `'LOCKED'`, `'ON_THE_WAY'`, `'ARRIVED'`, `'IN_PROGRESS'`, `'WORK_COMPLETED'`, `'PAYMENT_PENDING'`, `'COMPLETED'`, `'CANCELED'`. |
| `selectedTukangId` | `string?` | ID tukang yang dipilih (*locked*) oleh user. |
| `selectedTukangName` | `string?` | Nama tukang terpilih. |
| `bids` | `array<map>` | Penawaran dari tukang: `[{ "tukangId": string, "tukangName": string, "tukangPhoto": string, "tukangRating": number, "estimatedPrice": number, "note": string, "createdAt": timestamp }]`. |
| `finalBill` | `map?` | Rincian biaya setelah inspeksi: `{ "items": [{ "title": string, "amount": number }], "totalAmount": number, "approvedByUser": boolean, "createdAt": timestamp }`. |
| `beforePhotos` | `array<string>` | Foto kondisi fisik sebelum pekerjaan dimulai (diunggah tukang). |
| `afterPhotos` | `array<string>` | Foto kondisi fisik sesudah pekerjaan selesai (diunggah tukang). |
| `paymentMethod` | `string?` | `'doku'` atau `'cash'`. |
| `paymentStatus` | `string?` | `'unpaid'`, `'paid'`. |
| `dokuInvoiceId` | `string?` | ID transaksi resmi dari DOKU Payment Gateway. |
| `rating` | `map?` | Review user: `{ "stars": number, "review": string, "createdAt": timestamp }`. |
| `cancelData` | `map?` | `{ "canceledBy": "user"|"tukang", "reason": string, "gasFeeCompensated": boolean, "canceledAt": timestamp }`. |
| `createdAt` | `timestamp` | Waktu posting tiket keluhan. |
| `updatedAt` | `timestamp` | Waktu perubahan status terakhir. |

---

### 2.4. Sub-Koleksi `tickets/{ticketId}/chats`
Menyimpan riwayat obrolan pesan instan antara user dan tukang untuk tiket terkait.

| Field | Tipe Data | Deskripsi |
| :--- | :--- | :--- |
| `id` | `string` | ID Pesan unik. |
| `senderId` | `string` | ID pengirim (User UID atau Tukang UID). |
| `senderRole` | `string` | `'user'` atau `'tukang'`. |
| `text` | `string?` | Isi teks pesan. |
| `imageUrl` | `string?` | URL gambar lampiran di chat (opsional). |
| `isRead` | `boolean` | Status apakah pesan sudah dibaca pihak lawan. |
| `timestamp` | `timestamp` | Waktu pengiriman pesan. |

---

### 2.5. Koleksi `withdrawals`
Menyimpan riwayat dan permohonan penarikan saldo dompet mitra tukang ke rekening bank / e-wallet.

| Field | Tipe Data | Deskripsi |
| :--- | :--- | :--- |
| `id` | `string` | ID Permohonan penarikan dana. |
| `tukangId` | `string` | ID Tukang pemohon. |
| `tukangName` | `string` | Nama lengkap tukang. |
| `amount` | `number` | Jumlah nominal penarikan dana (Rupiah). |
| `payoutTarget` | `map` | `{ "type": "bank"|"ewallet", "provider": "BCA"|"DANA", "accountNumber": "2102198", "accountName": "Ahmad" }`. |
| `status` | `string` | `'pending'`, `'approved'`, `'rejected'`. |
| `adminNote` | `string?` | Catatan transfer admin / nomor referensi mutasi. |
| `createdAt` | `timestamp` | Waktu permohonan diajukan. |
| `processedAt` | `timestamp?` | Waktu admin menyetujui / mentransfer dana. |

---

## 3. COMPOSITE INDEXES FIRESTORE

Tambahkan indeks komposit berikut di `firestore.indexes.json` untuk mendukung query berkecepatan tinggi:

```json
{
  "indexes": [
    {
      "collectionGroup": "tickets",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "tickets",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "tickets",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "selectedTukangId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "tukang",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "verificationStatus", "order": "ASCENDING" },
        { "fieldPath": "isOnline", "order": "ASCENDING" },
        { "fieldPath": "isSuspended", "order": "ASCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

---

## 4. ATURAN KEAMANAN FIRESTORE (`firestore.rules`)

Aturan ini melindungi data sensitif, memastikan integritas *state machine*, dan membatasi aksi tukang yang sedang terkena suspend:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper Functions
    function isAuthenticated() {
      return request.auth != null;
    }
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    function isAdmin() {
      return isAuthenticated() && request.auth.token.admin == true;
    }
    function isTukangActive(tukangId) {
      let tukangData = get(/databases/$(database)/documents/tukang/$(tukangId)).data;
      return tukangData.verificationStatus == 'verified' && 
             (tukangData.isSuspended == false || tukangData.suspendedUntil < request.time);
    }

    // Rules User
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isOwner(userId);
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if isAdmin();
    }

    // Rules Tukang
    match /tukang/{tukangId} {
      allow read: if isAuthenticated();
      allow create: if isOwner(tukangId);
      // Tukang tidak boleh mengubah verifikasi atau suspensi sendiri
      allow update: if (isOwner(tukangId) && 
                        !request.resource.data.diff(resource.data).affectedKeys()
                        .hasAny(['verificationStatus', 'isSuspended', 'suspendedUntil', 'walletBalance']))
                    || isAdmin();
      allow delete: if isAdmin();
    }

    // Rules Tiket
    match /tickets/{ticketId} {
      allow read: if isAuthenticated();
      // Hanya user yang bisa membuat tiket baru
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      // Update tiket dikontrol oleh user pembuat atau tukang yang ditunjuk / admin
      allow update: if isAuthenticated() && (
        resource.data.userId == request.auth.uid ||
        resource.data.selectedTukangId == request.auth.uid ||
        (resource.data.status == 'OPEN' || resource.data.status == 'BIDDING') // Untuk submitting bid
      );
      allow delete: if isAdmin();

      // Sub-koleksi Chats
      match /chats/{messageId} {
        allow read, write: if isAuthenticated() && (
          get(/databases/$(database)/documents/tickets/$(ticketId)).data.userId == request.auth.uid ||
          get(/databases/$(database)/documents/tickets/$(ticketId)).data.selectedTukangId == request.auth.uid ||
          isAdmin()
        );
      }
    }

    // Rules Permohonan Penarikan Dana
    match /withdrawals/{withdrawId} {
      allow read: if isAuthenticated() && (resource.data.tukangId == request.auth.uid || isAdmin());
      allow create: if isAuthenticated() && request.resource.data.tukangId == request.auth.uid && isTukangActive(request.auth.uid);
      allow update, delete: if isAdmin();
    }
  }
}
```

---

## 5. STRUKTUR DAN ATURAN CLOUD STORAGE (`storage.rules`)

### 5.1. Struktur Folder Bucket
* `users/{userId}/profile.jpg` $\rightarrow$ Foto profil pengguna.
* `tukang/{tukangId}/ktp.jpg` $\rightarrow$ **Sensitif:** Foto KTP mitra (Hanya bisa diakses oleh Tukang terkait & Admin).
* `tukang/{tukangId}/profile.jpg` $\rightarrow$ Foto profil publik tukang.
* `tickets/{ticketId}/issues/{photoId}.jpg` $\rightarrow$ Foto keluhan awal dari pengguna.
* `tickets/{ticketId}/before/{photoId}.jpg` $\rightarrow$ Foto kondisi sebelum pengerjaan.
* `tickets/{ticketId}/after/{photoId}.jpg` $\rightarrow$ Foto hasil pengerjaan tuntas.
* `tickets/{ticketId}/chat/{photoId}.jpg` $\rightarrow$ Lampiran gambar dalam pesan chat.

### 5.2. Aturan Keamanan Storage (`storage.rules`)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Foto Profil Pengguna & Tukang
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Foto KTP Mitra Tukang (Sangat Rahasia)
    match /tukang/{tukangId}/ktp.jpg {
      allow read: if request.auth != null && (request.auth.uid == tukangId || request.auth.token.admin == true);
      allow write: if request.auth != null && request.auth.uid == tukangId;
    }

    // Foto Pengerjaan Tiket & Bukti
    match /tickets/{ticketId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```
