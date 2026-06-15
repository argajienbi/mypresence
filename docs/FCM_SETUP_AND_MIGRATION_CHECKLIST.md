# FCM Setup & Migration Checklist

Dokumen ini adalah catatan wajib saat mengaktifkan FCM atau memindahkan project Firebase/database untuk aplikasi **MYPRESENCE**. Tujuannya sederhana: jangan sampai push notification mati lagi hanya karena satu role IAM lupa ditambahkan. Cloud sangat senang membuat hal kecil berubah jadi drama, jadi kita tulis semuanya di sini.

---

## 1. Arsitektur FCM MYPRESENCE

Alur normal push notification:

```text
mypresence app login
  ↓
Firebase Messaging membuat token device
  ↓
Token disimpan ke Firestore
  ↓
Token juga dimirror ke RTDB untuk fallback/debug
  ↓
admin_web/myadmin membuat notification_queue lewat Cloud Functions
  ↓
processNotificationQueue mengambil token aktif
  ↓
FCM dikirim ke device
```

Path token utama:

```text
Firestore:
companies/{companyId}/users/{uid}/fcm_tokens/{tokenId}

RTDB mirror:
companies/{companyId}/users/{uid}/fcm_tokens/{tokenId}

RTDB debug status:
companies/{companyId}/users/{uid}/fcm_token_status
```

Catatan penting:

- Firestore adalah sumber utama token untuk admin/token health.
- RTDB mirror dipakai sebagai fallback backend dan debugging.
- Kalau Firestore kosong tetapi RTDB mirror ada, backend masih bisa membaca token jika function sudah mendukung fallback.
- Kalau dua-duanya kosong, push notification tidak mungkin terkirim. Mengirim push tanpa token itu seperti mengirim paket tanpa alamat, lalu menyalahkan kurir.

---

## 2. File penting di repo `mypresence`

### `lib/firebase_options.dart`

Pastikan semua platform mengarah ke project Firebase baru.

Untuk Android minimal harus cocok:

```dart
projectId: 'mypresence-db',
databaseURL: 'https://mypresence-db-default-rtdb.asia-southeast1.firebasedatabase.app',
storageBucket: 'mypresence-db.firebasestorage.app',
messagingSenderId: '911576285238',
```

Jika pindah project lagi, file ini harus dibuat ulang dari Firebase CLI / FlutterFire CLI.

### `android/app/google-services.json`

Pastikan file ini berasal dari Firebase project baru.

Cek nilai ini:

```json
{
  "project_info": {
    "project_number": "...",
    "firebase_url": "https://...firebaseio.com atau https://...firebasedatabase.app",
    "project_id": "...",
    "storage_bucket": "..."
  }
}
```

`project_number` harus sama dengan `messagingSenderId` di `firebase_options.dart`.

### `lib/core/firestore_paths.dart`

Path FCM token harus tetap:

```dart
companies/{companyId}/users/{uid}/fcm_tokens/{tokenId}
```

Jangan ubah path ini tanpa menyesuaikan `myadmin/functions/index.js` dan halaman Token Health.

### `lib/services/push_notification_service.dart`

Service ini bertanggung jawab untuk:

- meminta izin notifikasi,
- mengambil token FCM,
- menyimpan token ke Firestore,
- mirror token ke RTDB,
- menulis debug status ke RTDB,
- menangani foreground/background notification.

Path debug yang wajib dicek saat masalah:

```text
companies/{companyId}/users/{uid}/fcm_token_status
```

Jika status berisi `error`, baca `last_error`.

---

## 3. Checklist membuat / migrasi Firebase project baru

### A. Buat dan aktifkan service Firebase

Di Firebase Console project baru, aktifkan:

```text
Authentication
Realtime Database
Cloud Firestore
Cloud Storage
Cloud Messaging
Cloud Functions
```

Untuk Realtime Database, catat:

```text
Database URL
Database instance name
Region
```

Contoh saat ini:

```text
Project ID: mypresence-db
Project Number: 911576285238
RTDB URL: https://mypresence-db-default-rtdb.asia-southeast1.firebasedatabase.app
RTDB Instance: mypresence-db-default-rtdb
Region: asia-southeast1
```

### B. Update config Flutter

Jalankan FlutterFire config atau ambil manual dari Firebase Console.

Pastikan file berikut berubah ke project baru:

```text
lib/firebase_options.dart
android/app/google-services.json
```

Setelah itu build ulang aplikasi dan install ulang di HP.

### C. Login ulang app mobile

Setelah install app baru:

```text
1. Logout dari app lama jika perlu.
2. Clear data app jika token lama membandel.
3. Install build terbaru.
4. Login ulang.
5. Izinkan notifikasi.
6. Tunggu 5-10 detik.
```

Lalu cek RTDB:

```text
companies/{companyId}/users/{uid}/fcm_token_status
```

Status yang sehat:

```json
{
  "status": "registered" atau "refreshed",
  "permission_status": "authorized",
  "statusbar_allowed": true,
  "token_id": "...",
  "last_error": ""
}
```

Lalu cek token:

```text
Firestore:
companies/{companyId}/users/{uid}/fcm_tokens/{tokenId}

RTDB:
companies/{companyId}/users/{uid}/fcm_tokens/{tokenId}
```

---

## 4. Checklist backend `myadmin` / Cloud Functions

Repo backend/admin saat ini berada di:

```text
argajienbi/myadmin
```

Function penting:

```text
createUserNotificationAndPushCallable
processNotificationQueue
resetAttendanceReminderDedupeCallable
scheduledAttendanceReminder
syncApprovedLeaveByDate
rebuildApprovedLeaveByDateCallable
```

Di `functions/index.js`, pastikan config project baru benar:

```js
const EXPECTED_PROJECT_ID = "mypresence-db";
const EXPECTED_DATABASE_URL =
  "https://mypresence-db-default-rtdb.asia-southeast1.firebasedatabase.app";
const EXPECTED_DATABASE_INSTANCE = "mypresence-db-default-rtdb";
const REGION = "asia-southeast1";
```

Deploy functions harus eksplisit:

```bash
cd ~/myadmin
firebase use mypresence-db
firebase deploy --only functions --project mypresence-db
```

Cek project aktif:

```bash
firebase use
firebase projects:list
firebase functions:list --project mypresence-db
```

Jangan cuma menjalankan:

```bash
firebase deploy --only functions
```

kalau `.firebaserc` belum dicek. Ini cara paling elegan untuk deploy ke project yang salah, tentu saja sambil membuang waktu manusia.

---

## 5. IAM yang wajib dicek setelah migrasi

Ini bagian yang pernah menjadi penyebab utama FCM gagal walaupun token sudah benar.

Masuk ke:

```text
Google Cloud Console
→ IAM & Admin
→ IAM
→ pilih project Firebase baru
```

Pastikan project benar:

```text
Project ID: mypresence-db
Project Number: 911576285238
```

Cari service account runtime Cloud Functions / Cloud Run. Biasanya:

```text
PROJECT_NUMBER-compute@developer.gserviceaccount.com
```

atau service account yang terlihat di:

```text
Cloud Run
→ pilih service function
→ Security / Details
→ Service account
```

Role yang perlu ada untuk notifikasi berjalan:

```text
Firebase Realtime Database Admin
Firebase Cloud Messaging API Admin
Cloud Datastore User / Firestore User
Cloud Storage for Firebase Admin
```

Untuk testing darurat, boleh sementara beri:

```text
Editor
```

Setelah semua stabil, kurangi lagi ke role spesifik. Memberi `Editor` itu seperti memberi kunci semua ruangan ke tukang servis. Kadang perlu untuk debugging, tapi jangan dijadikan gaya hidup.

### Gejala IAM salah

Jika Cloud Functions log berisi:

```text
@firebase/database: FIREBASE WARNING:
Provided authentication credentials for the app named "[DEFAULT]" are invalid.
Make sure the "credential" property provided to initializeApp() is authorized
```

maka masalahnya bukan token, bukan owner, bukan path RTDB. Masalahnya adalah **service account Cloud Functions belum punya izin akses ke RTDB project baru**.

Solusi:

```text
1. Tambahkan role IAM yang benar ke service account runtime.
2. Tunggu 1-3 menit.
3. Deploy ulang functions.
4. Test push lagi.
```

---

## 6. Validasi end-to-end setelah migrasi

### A. Validasi dari app mobile

Cek di RTDB:

```text
companies/{companyId}/users/{uid}/fcm_token_status
companies/{companyId}/users/{uid}/fcm_tokens
```

Cek di Firestore:

```text
companies/{companyId}/users/{uid}/fcm_tokens
```

Minimal harus ada satu token aktif:

```json
{
  "active": true,
  "permission_status": "authorized",
  "statusbar_allowed": true,
  "token": "...",
  "token_id": "...",
  "uid": "...",
  "company_id": "..."
}
```

### B. Validasi dari admin web

Buka:

```text
Log Notifikasi
→ Kesehatan Token
→ Refresh Token Health
```

Harus terlihat:

```text
Push Ready: 1 atau lebih
Permission Blocked: 0
No Active Token: 0
```

### C. Test push

Di menu:

```text
Log Notifikasi
→ Debug Center / Kesehatan Token
→ Uji Push
```

Hasil sehat:

```text
HP menerima notifikasi.
Antrean Push Notification terisi lalu diproses.
Log Detail Pengiriman FCM muncul status success.
```

### D. Cek log function

```bash
firebase functions:log --only createUserNotificationAndPushCallable --project mypresence-db -n 50
firebase functions:log --only processNotificationQueue --project mypresence-db -n 50
firebase functions:log --only resetAttendanceReminderDedupeCallable --project mypresence-db -n 50
```

---

## 7. Troubleshooting cepat

### Token Health kosong

Cek:

```text
Firestore companies/{companyId}/users/{uid}/fcm_tokens
RTDB companies/{companyId}/users/{uid}/fcm_tokens
RTDB companies/{companyId}/users/{uid}/fcm_token_status
```

Kemungkinan:

```text
App belum login ulang.
App masih build lama.
Notifikasi belum diizinkan.
Firestore belum aktif.
Rules Firestore menolak write.
```

### `fcm_token_status` berisi error Firestore

Contoh:

```text
[cloud_firestore/unavailable]
```

Cek:

```text
Firestore Database sudah dibuat?
Firestore rules mengizinkan path token?
Internet/device stabil?
```

Untuk mencegah token hilang, pastikan app juga mirror token ke RTDB.

### Test Push gagal `functions/internal`

Cek function log:

```bash
firebase functions:log --only createUserNotificationAndPushCallable --project mypresence-db -n 50
```

Jika ada warning credential `[DEFAULT] invalid`, perbaiki IAM service account runtime.

### Notifikasi dobel

Kemungkinan:

```text
Ada lebih dari satu token aktif untuk user/device yang sama.
Tombol test ditekan lebih dari sekali.
Ada token lama yang belum dinonaktifkan.
Foreground notification dan system notification sama-sama tampil.
```

Cek:

```text
Firestore/RTDB fcm_tokens
```

Pastikan hanya token terbaru yang `active: true` untuk platform/device yang sama.

### Queue dibuat tapi tidak terkirim

Cek:

```bash
firebase functions:log --only processNotificationQueue --project mypresence-db -n 50
```

Cek juga:

```text
companies/{companyId}/notification_queue
companies/{companyId}/notification_delivery_logs
companies/{companyId}/notification_logs
```

---

## 8. Catatan owner/admin setelah migrasi

Agar callable admin bisa mengirim notifikasi, user admin/owner harus ada di path company-level:

```text
company_users/{companyId}/{adminUid}
companies/{companyId}/users/{adminUid}
users/{adminUid}
```

Field minimal:

```json
{
  "uid": "...",
  "company_id": "...",
  "role": "owner atau admin",
  "status_akun": "active",
  "active": true,
  "is_owner": true
}
```

Untuk owner global, boleh ada:

```json
{
  "is_owner": true,
  "is_system_owner": true,
  "bootstrap_owner": true
}
```

Jangan mengandalkan UI owner mode saja. Cloud Function tetap butuh data akses company-level. Ya, bahkan owner perlu dicatat di meja resepsionis lokal, karena sistem suka birokrasi.

---

## 9. Checklist ringkas saat pindah Firebase lagi

Gunakan ini sebagai daftar centang cepat:

```text
[ ] Buat Firebase project baru.
[ ] Aktifkan Auth, RTDB, Firestore, Storage, Messaging, Functions.
[ ] Catat Project ID, Project Number, RTDB URL, database instance, bucket.
[ ] Update lib/firebase_options.dart.
[ ] Update android/app/google-services.json.
[ ] Build ulang dan install ulang app.
[ ] Login ulang user di app.
[ ] Izinkan notifikasi.
[ ] Cek fcm_token_status di RTDB.
[ ] Cek fcm_tokens di Firestore.
[ ] Cek fcm_tokens mirror di RTDB.
[ ] Update myadmin/functions/index.js config project/database.
[ ] Deploy functions dengan --project PROJECT_ID.
[ ] Cek firebase use dan firebase projects:list.
[ ] Buka IAM & Admin → IAM.
[ ] Tambahkan role runtime service account:
    [ ] Firebase Realtime Database Admin
    [ ] Firebase Cloud Messaging API Admin
    [ ] Cloud Datastore User / Firestore User
    [ ] Cloud Storage for Firebase Admin
[ ] Buka myadmin → Log Notifikasi → Refresh Token Health.
[ ] Test Push.
[ ] Cek processNotificationQueue log.
[ ] Cek delivery logs.
[ ] Jika ada duplicate notification, bersihkan token lama.
```

---

## 10. Command penting

```bash
# Cek project aktif
firebase use

# Lihat semua project
firebase projects:list

# Deploy functions ke project benar
firebase deploy --only functions --project mypresence-db

# Lihat function aktif
firebase functions:list --project mypresence-db

# Log callable test push
firebase functions:log --only createUserNotificationAndPushCallable --project mypresence-db -n 50

# Log queue processor
firebase functions:log --only processNotificationQueue --project mypresence-db -n 50

# Log reset dedupe
firebase functions:log --only resetAttendanceReminderDedupeCallable --project mypresence-db -n 50
```

---

## 11. Kesimpulan insiden migrasi terakhir

Masalah terakhir bukan karena:

```text
token FCM
Firestore kosong
RTDB path user
owner mode
build app lama
```

Akar masalahnya adalah:

```text
Service account Cloud Functions belum punya role IAM yang cukup untuk akses RTDB project baru.
```

Setelah role IAM ditambahkan, test push langsung muncul di HP.

Catatan untuk masa depan: kalau semua data terlihat benar tapi Cloud Functions log menulis credential `[DEFAULT] invalid`, langsung cek IAM. Jangan ulangi ritual menyiksa database, kasihan juga dia meskipun cuma JSON.
