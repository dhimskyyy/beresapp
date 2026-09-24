# Hasil Audit Project Beres

Tanggal audit: 23 September 2026  
Scope: aplikasi Flutter User, aplikasi Flutter Mitra/Tukang, dan web Admin.

## Ringkasan Eksekutif

Project dapat dikompilasi pada kondisi saat ini, tetapi belum siap disebut berjalan end-to-end secara production. Masalah terbesar bukan lagi routing dasar, melainkan autentikasi, otorisasi Firestore, persistence transaksi, dan cakupan test.

Status umum:

- **Web Admin:** build berhasil, route utama terdaftar, tetapi tidak memiliki login/guard admin. Data dan aksi masih bercampur antara `localStorage`, mock data, dan Firestore.
- **Aplikasi User:** navigasi tab dan route utama tersedia, validasi form login mencegah field kosong, tetapi repository login saat ini menerima kredensial apa pun dan membuat user baru secara otomatis.
- **Aplikasi Mitra:** navigasi tab dan onboarding tersedia, tetapi login juga menerima kredensial apa pun dan status verifikasi belum benar-benar membatasi akses.
- **Backend/security:** rules Firestore memiliki celah kritis yang memungkinkan user authenticated memodifikasi tiket yang bukan miliknya dan membuat tiket dengan user ID arbitrer.
- **Test:** hanya ada widget test template counter. Tidak ada test routing, autentikasi, state machine tiket, pembayaran, withdrawal, chat, admin action, atau E2E.

## Evidence Validasi

| Pemeriksaan | Hasil |
|---|---|
| `flutter analyze` dari `mobile/` | Tidak ada error compile; tersisa 10 info/lint/deprecation |
| `flutter test` dari `mobile/` | Lulus `1` test, tetapi hanya test template counter |
| `flutter build apk --debug` dari `mobile/` | Berhasil membuat APK debug |
| `npm run build` dari `admin/` | Berhasil; ada warning ukuran bundle > 500 kB |
| `npm run lint` dari `admin/` | Selesai dengan warning unused imports, purity, dan Fast Refresh |
| Vite HTTP smoke test | `/` dan `/tickets` mengembalikan HTTP `200` |
| Browser click E2E | Tidak terlaksana; CLI `agent-browser` tidak terpasang pada environment audit |
| Docker | Tidak tersedia, sehingga tidak ada emulator/infrastruktur Firestore lokal |

Build APK memvalidasi entrypoint default `mobile/lib/main.dart`, bukan otomatis seluruh runtime entrypoint `main_user.dart` dan `main_mitra.dart`. Kedua entrypoint tersebut tetap dianalisis melalui source review dan static analysis.

## Matriks Routing dan Navigasi

### User

| Area | Route/perpindahan | Status audit | Catatan |
|---|---|---|---|
| Root/auth gate | `/` -> `UserMainRouter` -> login atau `UserBottomNavWrapper` | Ada | Berbasis state `AuthBloc` |
| Login -> register | `/user-register` | Ada | `Navigator.pushNamed` |
| Home -> buat tiket | `/create-ticket` | Ada | Dipanggil dari tombol home dan shortcut |
| Bottom nav | Beranda, Pesanan, Pesan, Profil | Ada | Menggunakan `IndexedStack`, bukan URL route |
| Home -> detail ticket | `LiveTrackingPage` atau `TicketBidsPage` | Ada di handler | Perlu E2E untuk memastikan data state selalu benar |
| Pesanan -> tracking/bids | `MaterialPageRoute` | Ada di source | Bergantung pada list/state repository |
| Chat user | `ChatPage` | Ada di source | Persistence Firestore gagal akan jatuh diam-diam ke memory |
| Profil -> settings | `UserSettingsPage` | Ada | Return value settings diproses parent |
| Profil -> edit profile | `UserEditProfilePage` | Ada | Memperbarui state lokal/AuthBloc |
| Profil -> alamat | `UserAddressListPage` | Ada | CRUD alamat masih state lokal |
| Profil -> wallet/favorit/help/terms | `MaterialPageRoute` | Ada | Beberapa fitur hanya simulasi lokal |
| Login -> aplikasi mitra | Tidak ada handler navigasi aktif | Masalah UX | Teks “Buka Aplikasi Mitra” pada login user tampak hanya informasi, bukan tombol/route |

### Mitra/Tukang

| Area | Route/perpindahan | Status audit | Catatan |
|---|---|---|---|
| Root/auth gate | `/` -> `MitraMainRouter` -> login atau dashboard | Ada | Berbasis state `AuthBloc` |
| Login -> onboarding | `/tukang-onboarding` | Ada | `Navigator.pushNamed` |
| Bottom nav | Radar Job, Pengerjaan, Chat, Dompet, Profil | Ada | Menggunakan `IndexedStack` |
| Radar -> detail/active job/chat | `MaterialPageRoute` | Ada di source | Perlu validasi dengan data ticket nyata |
| Radar -> submit bid | Event `SubmitBidRequestedEvent` | Ada | Harga direct bid di-set `0`, berpotensi menghasilkan penawaran gratis/invalid |
| Pengerjaan -> active job | `MitraActiveJobPage` | Ada | Perubahan status memakai repository mock + fallback Firestore |
| Chat mitra | `ChatPage` | Ada | Error Firestore ditelan dan pesan tetap tampak terkirim lokal |
| Dompet -> withdrawal | `PaymentBloc` | Ada | Saldo langsung dipotong sebelum admin menyetujui payout |
| Profil -> edit service/payout | Modal dan event update | Ada di source | Persistence dan pembatasan status perlu diuji pada backend |
| Login Mitra -> akses dashboard | Login apa pun diterima | Masalah kritis | Status `pending_verification` dari Google juga dapat menjadi authenticated state |

### Admin Web

Route yang terdaftar di [App.jsx](admin/src/App.jsx#L16-L26):

- `/` Dashboard
- `/kyc` Verifikasi Mitra
- `/live-map` Lacak GPS
- `/tukang` Manajemen Tukang
- `/users` Daftar Pengguna
- `/tickets` Pantau Pekerjaan
- `/withdrawals` Pencairan Dana
- route tidak dikenal diarahkan ke `/`

Secara source, semua menu Sidebar memiliki target route. Smoke HTTP membuktikan Vite melayani halaman utama dan fallback route. Namun tidak ada autentikasi admin atau route guard.

## Temuan Kritis

### [CRITICAL] Login menerima kredensial apa pun

Evidence: [auth_repository_impl.dart](mobile/lib/data/repositories/auth_repository_impl.dart#L13-L27) dan [auth_repository_impl.dart](mobile/lib/data/repositories/auth_repository_impl.dart#L65-L86).

`loginUserWithEmail` dan `loginTukangWithEmail` tidak memeriksa password dan menggunakan `firstWhere(..., orElse: ...)` untuk membuat object user/tukang baru jika email tidak ditemukan. Akibatnya:

- email valid secara format + password apa pun dapat masuk;
- email kosong memang ditolak oleh validator UI, tetapi kredensial palsu tetap diterima;
- login tidak terhubung ke Firebase Auth;
- user baru tidak selalu tersimpan ke `_mockUsers`/`_mockTukangs` saat login fallback;
- autentikasi hilang saat proses mati/restart karena `_currentUser` hanya memory.

Dampak: kontrol akses aplikasi tidak dapat dipercaya.

### [CRITICAL] Firestore rules mengizinkan manipulasi tiket lintas user

Evidence: [firestore.rules](firestore.rules#L35-L47).

Temuan spesifik:

- `allow create` memakai `(... || true)`, sehingga setiap user authenticated dapat membuat tiket dengan `userId` siapa pun.
- `allow update` mengizinkan update jika status tiket `OPEN` atau `BIDDING`, tanpa memverifikasi bahwa request adalah tukang yang sesuai, user pemilik, atau field yang diubah hanya bid yang sah.
- Subkoleksi chat mengizinkan `read, write` untuk semua user authenticated pada semua tiket.
- `isTukangActive()` didefinisikan tetapi tidak dipakai untuk melindungi operasi.

Dampak: pembajakan tiket, perubahan status/harga, membaca chat pribadi, dan impersonasi user/tukang.

### [CRITICAL] Admin web tidak memiliki autentikasi dan otorisasi

Evidence: [App.jsx](admin/src/App.jsx#L16-L29), [AdminLayout.jsx](admin/src/components/layout/AdminLayout.jsx#L1-L14), dan [firebase.js](admin/src/firebase.js#L1-L20).

Admin langsung merender dashboard tanpa Firebase Auth, role check, atau route guard. Firebase web hanya menginisialisasi Firestore. Siapa pun yang mengetahui URL admin dapat membuka aksi KYC, suspend, dan withdrawal. Backend memang memiliki konsep `isAdmin()` di rules, tetapi aplikasi admin tidak melakukan sign-in admin.

### [HIGH] Aksi admin menampilkan sukses walau write Firestore gagal

Evidence: [AdminDataContext.jsx](admin/src/context/AdminDataContext.jsx#L224-L247), [AdminDataContext.jsx](admin/src/context/AdminDataContext.jsx#L254-L278), [AdminDataContext.jsx](admin/src/context/AdminDataContext.jsx#L285-L314), dan [AdminDataContext.jsx](admin/src/context/AdminDataContext.jsx#L353-L405).

Semua operasi melakukan optimistic update state lokal, menangkap error dengan `console.warn`, lalu tetap memanggil `showToast` sukses. Bila Firestore rules menolak write atau konfigurasi Firebase salah, operator melihat status sukses sementara data server tidak berubah. Reload/realtime merge dapat mengembalikan nilai lama.

### [HIGH] Admin tidak mengelola data user dari backend

Evidence: [AdminDataContext.jsx](admin/src/context/AdminDataContext.jsx#L124-L213).

`usersList` hanya diinisialisasi dari `localStorage` atau `initialUsersList`. Tidak ada `onSnapshot(collection(db, 'users'))`. Menu Daftar Pengguna terlihat seperti data operasional tetapi tidak realtime dan tidak menerima user yang mendaftar dari aplikasi.

### [HIGH] Pembayaran adalah simulasi dan tidak mengubah ticket secara konsisten

Evidence: [payment_repository_impl.dart](mobile/lib/data/repositories/payment_repository_impl.dart#L30-L105) dan [user_payment_modal.dart](mobile/lib/features/payment/pages/user_payment_modal.dart#L30-L81).

Invoice DOKU dibuat sebagai map dummy, QRIS memakai URL gambar, dan tombol “Simulasi Webhook Pembayaran Lunas” dapat mengubah UI tanpa webhook/payment provider nyata. `processPaymentSuccess` selalu menambah `125000` ke wallet `TKG-001`, terlepas dari ticket, nominal final bill, atau tukang terpilih, lalu mengembalikan ticket dummy completed. Tidak terlihat transaksi atomik atau update ticket Firestore.

Dampak: nominal pembayaran dapat salah, saldo tukang yang salah bertambah, dan status UI bisa berbeda dari backend.

### [HIGH] Withdrawal memotong saldo sebelum approval admin dan reject tidak mengembalikan saldo

Evidence: [payment_repository_impl.dart](mobile/lib/data/repositories/payment_repository_impl.dart#L108-L177).

Saat request withdrawal dibuat, saldo langsung dikurangi dan transaksi pending dibuat. Jika admin menolak withdrawal, tidak ada mekanisme refund/reversal pada payment repository. Ini dapat menghilangkan saldo mitra secara permanen.

### [HIGH] Error persistence disamarkan sebagai sukses lokal

Evidence: [ticket_repository_impl.dart](mobile/lib/data/repositories/ticket_repository_impl.dart#L200-L245), [chat_repository_impl.dart](mobile/lib/data/repositories/chat_repository_impl.dart#L75-L151), dan [supabase_storage_service.dart](mobile/lib/core/services/supabase_storage_service.dart#L24-L72).

Create ticket, chat, dan upload foto dapat mengembalikan fallback/local path ketika Firestore/Supabase gagal. UI kemudian menampilkan berhasil. Pada perangkat lain atau setelah restart, data dapat hilang atau URL foto tidak dapat diakses.

### [HIGH] Status verifikasi mitra belum menjadi authorization gate

Evidence: [auth_repository_impl.dart](mobile/lib/data/repositories/auth_repository_impl.dart#L135-L149), [main_mitra.dart](mobile/lib/main_mitra.dart#L99-L115), dan [tukang_onboarding_page.dart](mobile/lib/features/auth/pages/tukang_onboarding_page.dart#L370-L390).

`registerTukangWithEmail` membuat mitra dengan `verificationStatus: 'verified'`, sedangkan Google sign-in membuat `pending_verification` tetapi `AuthBloc` tetap mengeluarkan `TukangAuthenticatedState`. `MitraMainRouter` hanya memeriksa tipe state, bukan status verifikasi. Mitra pending dapat masuk dashboard dan berpotensi memakai fitur kerja.

## Temuan High/Medium Lainnya

### [HIGH] Tidak ada E2E aplikasi nyata

`mobile/test/widget_test.dart` hanya menguji `MyApp` counter template dari [main.dart](mobile/lib/main.dart#L1-L8). Test tidak menguji `main_user.dart` atau `main_mitra.dart`, form login, routing, ticket, chat, payment, wallet, atau profile. Test lulus tidak membuktikan aplikasi Beres lulus.

### [MEDIUM] Direct bid menggunakan nominal 0

Evidence: [mitra_job_feed_page.dart](mobile/lib/features/tukang/pages/mitra_job_feed_page.dart#L78-L101). Tombol 1-click mengirim `estimatedPrice: 0`. Jika backend tidak mengisi atau menolak nilai ini, user dapat menerima penawaran Rp0 atau proses lock memiliki nominal tidak valid.

### [MEDIUM] Rating dianggap berhasil setelah delay tetap

Evidence: [user_rating_modal.dart](mobile/lib/features/payment/pages/user_rating_modal.dart#L61-L91). UI menutup modal setelah delay 500 ms tanpa menunggu `TicketBloc` sukses/gagal. Gagal Firestore tetap dapat ditampilkan sebagai “Terima kasih”.

### [MEDIUM] Firestore realtime merge berpotensi menimpa/menyembunyikan state lokal

Evidence: [AdminDataContext.jsx](admin/src/context/AdminDataContext.jsx#L145-L205). Fallback demo selalu digabung dengan cloud, dan hanya mengganti state ketika snapshot tidak kosong. Tidak ada strategi konflik, timestamp/versioning, atau penanda sumber data. Data demo dapat tetap tampil di production dan perubahan lokal dapat tertimpa oleh snapshot.

### [MEDIUM] Admin bundle besar

`npm run build` berhasil tetapi menghasilkan JS minified sekitar 980 kB dan warning chunk >500 kB. Ini dapat memperlambat first load dashboard, terutama jaringan mobile.

### [LOW] Warning lint/deprecation belum dibereskan

Admin memiliki unused imports dan purity warning `Date.now()` saat render di [TukangListPage.jsx](admin/src/pages/TukangListPage.jsx#L303). Flutter memiliki warning import, `activeColor` deprecated, `value` deprecated, async context, dan unused/formatting lint. Tidak memblokir build, tetapi menurunkan signal kualitas dan dapat menyembunyikan defect baru.

### [LOW] `go_router`, `get_it`, dan dependency Firebase tertentu belum menunjukkan pemakaian jelas

[pubspec.yaml](mobile/pubspec.yaml#L20-L50) mendeklarasikan `go_router` dan `get_it`, tetapi entrypoint menggunakan named routes dan direct `MaterialPageRoute`; ini bukan bug langsung, tetapi menunjukkan arsitektur navigasi/DI belum konsisten.

## Hasil Audit Fungsional per Domain

### User: yang tampak sudah tersambung

- Login dan register mempunyai form validation dasar.
- Home, Pesanan, Pesan, dan Profil terhubung melalui bottom navigation.
- Create ticket memiliki route dan listener success/failure.
- Ticket bids memiliki aksi lock tukang.
- Live tracking memiliki aksi cancel, chat, kontak, pembayaran, dan rating pada source.
- Profile memiliki settings, edit profile, alamat, wallet, favorit, help, dan terms.

### User: belum dapat dianggap berfungsi benar

- Login tidak melakukan autentikasi nyata.
- Data user/ticket/chat/payment tidak durable secara konsisten.
- Payment dan webhook masih simulasi.
- Error backend sering dianggap success lokal.
- Tidak ada E2E untuk membuktikan perpindahan halaman dan state setelah kembali dari child page.

### Mitra: yang tampak sudah tersambung

- Login/onboarding mempunyai route.
- Bottom navigation memiliki 5 menu.
- Radar memuat ticket berdasarkan service, lokasi, radius.
- Bid, active job, foto before/after, invoice, chat, wallet, payout, dan profile memiliki handler source.

### Mitra: belum dapat dianggap berfungsi benar

- Login tidak memeriksa password/email terhadap backend.
- Status KYC tidak mengunci dashboard.
- Bidding langsung mengirim harga `0`.
- Payout memotong saldo sebelum approval.
- Foto/chat dapat sukses lokal meski upload/write backend gagal.

### Admin: yang tampak sudah tersambung

- Semua menu sidebar memiliki route.
- Filter/search/tab KYC, ticket, tukang, peta, user, withdrawal mempunyai state handler.
- KYC approve/reject, suspend/unsuspend, withdrawal approve/reject memiliki context action.
- Peta memiliki marker, filter status, search, dan fly-to.

### Admin: belum dapat dianggap berfungsi benar

- Tidak ada login admin.
- Data user bukan realtime dari Firestore.
- Aksi optimistic mengirim toast sukses walau server menolak.
- Tidak ada test click terhadap modal, filter, tab, dan mutation.
- Route fallback HTTP tersedia, tetapi browser-level rendering/click belum teruji karena `agent-browser` tidak terpasang.

## Rekomendasi Perbaikan Berurutan

1. **Blokir release dan tutup security rules.** Hapus `|| true`, batasi update tiket berdasarkan role/ownership/field diff, batasi chat ke owner atau tukang terpilih, dan gunakan custom claims admin.
2. **Implementasikan Firebase Auth sungguhan.** Login/register user dan mitra harus memakai Firebase Auth; jangan membuat identity fallback dari email. Simpan session secara resmi dan tangani logout/restart.
3. **Tambahkan Firebase Auth + route guard admin.** Semua mutation admin harus berasal dari user dengan custom claim admin.
4. **Pisahkan mock mode dari production mode.** Jangan fallback diam-diam setelah write gagal. Tampilkan failure state dan retry.
5. **Buat transaksi ticket/payment/wallet atomik di backend.** Nominal harus berasal dari final bill, tukang harus berasal dari ticket, dan webhook harus diverifikasi server-side.
6. **Ubah withdrawal menjadi ledger dengan status pending/approved/rejected.** Reserve saldo saat pending, refund otomatis saat rejected, dan cegah withdrawal ganda.
7. **Jadikan verification status sebagai gate.** Mitra pending/rejected tidak boleh menerima radar atau bid; registration default harus pending sampai admin approve.
8. **Perbaiki state success.** Rating, chat, ticket, upload, dan payment hanya menampilkan sukses setelah event/repository mengembalikan sukses.
9. **Ganti test template dengan test aplikasi.** Minimal tambahkan widget tests untuk user login kosong/salah, mitra login, auth gate, bottom nav, create ticket validation, bid-lock, payment failure/success, withdrawal rejection/refund, dan admin action.
10. **Tambahkan browser E2E admin.** Jalankan Playwright atau tool sejenis pada `/`, `/kyc`, `/live-map`, `/tukang`, `/users`, `/tickets`, `/withdrawals`, termasuk modal mutation dan route unknown.
11. **Tambahkan device E2E Flutter.** Jalankan user dan mitra pada target entrypoint masing-masing, bukan `main.dart` template.
12. **Bersihkan lint/dependency dan pecah bundle admin.** Hapus import tidak terpakai, ganti API deprecated, perbaiki async context, dan gunakan lazy route/component loading bila diperlukan.

## Addendum Audit Pembayaran & Penarikan

Audit lanjutan pada implementasi terbaru menunjukkan klasifikasi berikut.

### Pembayaran User: **Sandbox/demo dengan persistence parsial**

Evidence: [user_payment_modal.dart](mobile/lib/features/payment/pages/user_payment_modal.dart#L30-L81), [payment_repository_impl.dart](mobile/lib/data/repositories/payment_repository_impl.dart#L44-L153), dan [doku_config.dart](mobile/lib/core/constants/doku_config.dart#L1-L15).

- `createDokuInvoice` hanya menunggu 600 ms lalu membuat `invoiceId`, nomor VA, dan URL QRIS secara lokal.
- Tidak ada HTTP request ke `https://api-sandbox.doku.com` atau API DOKU lain.
- `DokuConfig` hanya berisi konstanta; belum dipakai oleh repository.
- `DOKU_SECRET_KEY` memiliki default value di source mobile. Secret key tidak boleh dikirim atau disimpan di APK; jika key tersebut aktif, perlu segera dirotasi dan dipindahkan ke backend.
- QRIS adalah gambar Unsplash, bukan QRIS invoice yang dikeluarkan gateway.
- Tombol UI bernama `Simulasi Webhook Pembayaran Lunas`, jadi pelunasan dipicu manual oleh user.
- Invoice tidak disimpan sebagai invoice aktif pada ticket sebelum konfirmasi.
- `processPaymentSuccess` membaca ticket dari Firestore bila bisa, lalu menulis status `COMPLETED/paid` dan `walletBalance`; tetapi error write hanya dicatat lewat `debugPrint` dan method tetap mengembalikan sukses.
- Tidak ada idempotency key/guard. Klik konfirmasi berulang dapat menambah pendapatan tukang lebih dari sekali.
- Jika ticket tidak ditemukan atau Firestore gagal dibaca, kode memakai fallback user, tukang `TKG-001`, nominal `125000`, dan data ticket dummy.
- CASH melewati flow invoice yang sama, padahal seharusnya memiliki konfirmasi pembayaran tunai yang berbeda.

**Kesimpulan pembayaran:** belum real production payment. Ini simulasi UI + write Firestore parsial, bukan integrasi DOKU dengan webhook terverifikasi.

### Saldo Mitra: **Hybrid local memory + Firestore**

Evidence: [payment_repository_impl.dart](mobile/lib/data/repositories/payment_repository_impl.dart#L155-L273).

- Saldo awal dan transaksi berasal dari static in-memory map.
- Saldo dibaca dari `tukang/{tukangId}.walletBalance` bila field tersedia.
- Riwayat withdrawal dibaca dari Firestore dan digabungkan ke transaksi local.
- Tidak ada collection ledger wallet sebagai sumber kebenaran tunggal.
- Update saldo memakai baca/tulis biasa, bukan transaksi Firestore/Cloud Function. Request bersamaan dapat menyebabkan lost update atau double credit.
- Error baca/write menghasilkan fallback atau log, sehingga UI dapat menampilkan saldo lokal seperti saldo server.

**Kesimpulan saldo:** semi-real untuk display dan sinkronisasi sederhana, tetapi belum aman sebagai ledger finansial.

### Penarikan Mitra: **Request real ke Firestore, transfer uang masih demo/manual**

Evidence: [tukang_wallet_page.dart](mobile/lib/features/payment/pages/tukang_wallet_page.dart#L430-L510), [payment_repository_impl.dart](mobile/lib/data/repositories/payment_repository_impl.dart#L275-L367), dan [AdminDataContext.jsx](admin/src/context/AdminDataContext.jsx#L390-L442).

- Validasi minimum Rp20.000, saldo, rekening, fee Rp2.500, dan nominal bersih sudah ada.
- Dokumen withdrawal benar-benar dicoba ditulis ke Firestore dengan status `pending`.
- Saldo lokal dan `tukang.walletBalance` langsung dikurangi saat request dibuat.
- Tidak ada integrasi bank, e-wallet, DOKU payout, atau disbursement API.
- Admin hanya mengubah status dokumen menjadi `approved` atau `rejected`; tidak ada transfer dana yang dijalankan.
- Receipt user menyebut “Diproses Instan” dan “< 15 menit”, padahal implementasi hanya membuat request ledger.
- Jika admin reject, code admin tidak mengembalikan saldo dan tidak membuat reversal transaction.
- Jika Firestore write gagal, repository tetap mengembalikan request sukses setelah perubahan memory lokal.
- Account payout yang diedit di wallet hanya mengirim `TukangProfileUpdatedEvent`; belum terlihat persistence langsung ke Firestore.
- Belum ada proteksi duplicate withdrawal, reservation ledger, idempotency, atau atomic transaction.

**Kesimpulan withdrawal:** request pencairan sudah semi-real karena tercatat ke Firestore, tetapi transfer uang nyata belum ada. Status `approved` berarti ditandai admin, bukan bukti transfer.

### Prioritas perbaikan pembayaran

1. Pindahkan pembuatan invoice, validasi nominal, webhook DOKU, dan credit wallet ke backend terpercaya/Cloud Functions.
2. Simpan `invoiceId`, amount, expiry, payment status, dan provider reference pada ticket/invoice collection.
3. Buat ledger wallet append-only dengan Firestore transaction atau server-side function; cegah double processing menggunakan payment ID unik.
4. Ubah withdrawal menjadi `pending -> approved -> paid` atau `rejected`, dengan reserve balance dan refund atomik ketika rejected.
5. Integrasikan payout provider nyata atau nyatakan fitur sebagai manual admin dan hapus klaim “instan”.
6. Jangan fallback ke ticket/tukang/nominal dummy pada jalur pembayaran production; fail closed jika data tidak ditemukan.
7. Tambahkan test double-click payment, duplicate webhook, nominal final bill, saldo tidak cukup, withdrawal reject/refund, Firestore failure, dan concurrent requests.

## Kesimpulan

Routing dasar user, mitra, dan admin **secara source sebagian besar tersedia dan tidak menunjukkan route target yang hilang**. Namun jawaban untuk “apakah semua berjalan sebagaimana mestinya” adalah **belum**. Autentikasi masih mock/permissive, admin tidak dilindungi login, Firestore rules memiliki bypass kritis, transaksi keuangan belum nyata/atomik, dan automated E2E hampir tidak ada. Prioritas pertama harus security rules dan autentikasi, kemudian konsistensi persistence/payment, baru penyempurnaan lint dan UX.
