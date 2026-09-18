# API & INTEGRATION SPECIFICATION (api_and_integration.md)

Dokumen ini mendefinisikan integrasi eksternal untuk sistem **Beres**, meliputi **DOKU Payment Gateway**, **Firebase Cloud Messaging (FCM)**, dan **Layanan Peta OpenStreetMap (Leaflet & Geolocation)**.

---

## 1. INTEGRASI DOKU PAYMENT GATEWAY

Integrasi pembayaran ditangani melalui Firebase Cloud Functions untuk menjaga kerahasiaan `Secret Key` dan mencegah manipulasi data dari sisi klien mobile.

```
[User App] ──(1) Minta Link Bayar──> [Cloud Function /createPayment]
                                             │
                                      (2) Panggil DOKU Checkout API
                                             │
                                             ▼
[User App] <──(3) Doku Checkout URL/VA───────┘
    │
    └──(4) Bayar via M-Banking (BCA/BRI/Mandiri/QRIS)
              │
              ▼
          [DOKU Server]
              │
              └──(5) Webhook Notifikasi Bayar──> [Cloud Function /dokuWebhook]
                                                        │
                                                 (6) Verifikasi Signature HMAC
                                                        │
                                                 (7) Update Firestore:
                                                     - ticket.paymentStatus = 'paid'
                                                     - tukang.walletBalance += total
```

### 1.1. Endpoint DOKU Checkout (Joko / DOKU Core API)
* **Sandbox Base URL:** `https://api-sandbox.doku.com`
* **Production Base URL:** `https://api.doku.com`
* **Path:** `/checkout/v1/payment`
* **Metode:** `POST`

#### Headers Permintaan:
```http
Client-Id: {DOKU_CLIENT_ID}
Request-Id: {UUIDv4_UNIQUE_ID}
Request-Timestamp: 2026-09-18T08:30:00Z
Signature: HMAC-SHA256(Client-Id + Request-Id + Request-Timestamp + Request-Target + Digest)
Content-Type: application/json
```

#### Contoh Payload Pembuatan Transaksi:
```json
{
  "order": {
    "invoice_number": "INV-BERES-20260918-001",
    "amount": 150000,
    "currency": "IDR",
    "callback_url": "https://beresapp.web.app/payment-success",
    "line_items": [
      {
        "name": "Servis Cuci AC 1 PK",
        "price": 75000,
        "quantity": 1
      },
      {
        "name": "Pembersihan Saluran Pembuangan",
        "price": 75000,
        "quantity": 1
      }
    ]
  },
  "payment": {
    "payment_due_date": 60,
    "payment_method_types": [
      "VIRTUAL_ACCOUNT_BCA",
      "VIRTUAL_ACCOUNT_BRI",
      "VIRTUAL_ACCOUNT_BNI",
      "VIRTUAL_ACCOUNT_MANDIRI",
      "QRIS",
      "OVO",
      "SHOPEEPAY"
    ]
  },
  "customer": {
    "id": "USR1001",
    "name": "Budi Santoso",
    "email": "budi@gmail.com",
    "phone": "081234567890"
  },
  "additional_info": {
    "ticket_id": "TCK9001",
    "tukang_id": "TKG2001"
  }
}
```

### 1.2. Spesifikasi Webhook Notifikasi Pembayaran
DOKU akan mengirimkan callback HTTP `POST` ke Cloud Function URL:
`https://us-central1-beresapp.cloudfunctions.net/dokuPaymentWebhook`

#### Validasi Signature Webhook:
Cloud Function memverifikasi keabsahan request dengan mencocokkan signature:
$$\text{Signature} = \text{HMAC-SHA256}(\text{RawBody}, \text{DOKU\_SECRET\_KEY})$$

#### Payload Notifikasi DOKU:
```json
{
  "order": {
    "invoice_number": "INV-BERES-20260918-001",
    "amount": 150000
  },
  "transaction": {
    "status": "SUCCESS",
    "date": "2026-09-18T08:35:12Z",
    "original_request_id": "req-uuid-12345"
  },
  "channel": {
    "id": "VIRTUAL_ACCOUNT_BCA"
  },
  "additional_info": {
    "ticket_id": "TCK9001",
    "tukang_id": "TKG2001"
  }
}
```

#### Respons Cloud Function ke DOKU:
Wajib mengembalikan HTTP Status `200 OK` dalam waktu $< 5$ detik:
```json
{
  "status": "SUCCESS",
  "message": "Payment verified and recorded successfully"
}
```

---

## 2. INTEGRASI FIREBASE CLOUD MESSAGING (FCM)

Notifikasi push dikirimkan secara terprogram menggunakan Firebase Admin SDK di Cloud Functions saat terjadi perubahan status dokumen Firestore.

### 2.1. Matriks Notifikasi & Target Penerima

| Event Pemicu | Target Penerima | Judul Notifikasi | Isi Pesan |
| :--- | :--- | :--- | :--- |
| **Tiket Baru Dibuat** | Tukang terdekat sesuai kategori | *"Pekerjaan Baru di Dekat Anda!"* | *"[Kategori]: [Judul Tiket] - Ketuk untuk mengajukan penawaran."* |
| **Penawaran Baru Masuk** | User pembuat tiket | *"Ada Penawaran Baru Masuk"* | *"[Nama Tukang] mengajukan penawaran Rp [Harga]. Cek profilnya!"* |
| **User Lock Tukang** | Tukang terpilih | *"Selamat! Penawaran Anda Dipilih"* | *"User telah mengunci Anda untuk pekerjaan: [Judul]. Siapkan peralatan."* |
| **Tukang Menuju Lokasi** | User pembuat tiket | *"Tukang Sedang Menuju Rumah Anda"* | *"[Nama Tukang] sedang dalam perjalanan. Pantau posisinya di peta."* |
| **Rincian Biaya Diinput** | User pembuat tiket | *"Rincian Biaya Perbaikan Siap"* | *"Tukang telah menginput tagihan Rp [Total]. Mohon periksa & setujui."* |
| **Pekerjaan Selesai** | User pembuat tiket | *"Pekerjaan Telah Selesai!"* | *"Tukang telah mengunggah bukti kerja. Silakan periksa & selesaikan pembayaran."* |
| **Pembayaran Berhasil** | Tukang terpilih | *"Pembayaran Diterima!"* | *"Dana sebesar Rp [Total] telah masuk ke saldo dompet Anda."* |
| **Pesan Chat Masuk** | User / Tukang lawan bicara | *"[Nama Pengirim]"* | *"[Cuplikan isi teks obrolan]"* |
| **Akun Disuspend** | Tukang | *"Peringatan Akun Ditangguhkan"* | *"Akun Anda dinonaktifkan selama 3 hari karena: [Alasan]."* |

### 2.2. Format Data Payload FCM
```json
{
  "notification": {
    "title": "Tukang Sedang Menuju Rumah Anda",
    "body": "Ahmad Subarjo sedang dalam perjalanan ke alamat Anda."
  },
  "data": {
    "click_action": "FLUTTER_NOTIFICATION_CLICK",
    "type": "JOB_STATUS_UPDATE",
    "ticketId": "TCK9001",
    "status": "ON_THE_WAY"
  },
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "beres_jobs_channel",
      "sound": "default"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "default"
      }
    }
  }
}
```

---

## 3. INTEGRASI OPENSTREETMAP (OSM) & GEOLOKASI

Penggunaan OpenStreetMap bebas royalti dan tidak memerlukan pendaftaran kartu kredit / API key Google Cloud.

### 3.1. Konfigurasi Tile Server Leaflet
* **Tile URL:** `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
* **Subdomain:** `['a', 'b', 'c']`
* **Attribution:** `&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors`
* **User-Agent:** Wajib menyertakan User-Agent aplikasi (`BeresApp/1.0 (contact: support@beresapp.com)`) sesuai kebijakan penggunaan OSM.

### 3.2. Geocoding & Reverse Geocoding (Nominatim API)
Mengonversi titik koordinat latitude/longitude menjadi nama jalan dan kelurahan yang dapat dibaca manusia.

* **Endpoint Reverse Geocoding:**
  `https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat={LAT}&lon={LNG}`
* **Contoh Respons:**
```json
{
  "place_id": 28918231,
  "lat": "-6.23821",
  "lon": "106.81234",
  "display_name": "Jl. Mawar No. 12, RT 01/RW 03, Kebayoran Baru, Jakarta Selatan, DKI Jakarta, 12160, Indonesia",
  "address": {
    "road": "Jl. Mawar",
    "house_number": "12",
    "suburb": "Kebayoran Baru",
    "city": "Jakarta Selatan",
    "state": "DKI Jakarta",
    "postcode": "12160",
    "country": "Indonesia"
  }
}
```

### 3.3. Penghitungan Jarak Radius (Rumus Haversine)
Digunakan pada aplikasi mobile dan backend untuk memfilter tiket yang berada di dalam radius tukang (misal $\le 10$ km):

```dart
double calculateDistanceInKm(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadiusKm = 6371.0;
  final double dLat = _degreesToRadians(lat2 - lat1);
  final double dLon = _degreesToRadians(lon2 - lon1);

  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) *
          cos(_degreesToRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degreesToRadians(double degrees) {
  return degrees * pi / 180;
}
```

### 3.4. Protokol Transmisi Live GPS Tukang
Saat tukang mengubah status menjadi `ON_THE_WAY`:
1. Service lokasi latar belakang (*Background Location Service*) aktif pada perangkat mitra.
2. Koordinat GPS ditransmisikan setiap **8 detik** atau setiap berpindah minimal **15 meter** ke dokumen Firestore:
   `tukang/{tukangId}` pada field `currentLocation = { lat, lng, updatedAt }`.
3. User App mendengarkan (*listen*) stream `currentLocation` tukang terpilih dan menggerakkan marker motor/mobil di atas peta OpenStreetMap secara mulus (*interpolated marker animation*).
4. Saat status berganti ke `ARRIVED`, background location service langsung dimatikan untuk menghemat daya baterai.
