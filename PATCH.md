# PATCH.md - MYPRESENCE FCM Token Permission Resync

Dokumen ini adalah instruksi kerja untuk Codex pada repo `argajienbi/mypresence`.

Fokus patch ini hanya memperbaiki sinkronisasi status izin notifikasi/token FCM agar admin_web Token Health tidak terus menampilkan `Permission Blocked/Denied` ketika izin notifikasi Android sebenarnya sudah ON.

Patch sebelumnya untuk UI, kamera, history, tombol absen, maps, approval routing, FCM receiver, dan local fallback sudah dianggap selesai. Jangan disentuh lagi kecuali ada error compile langsung. Karena menyentuh fitur yang sudah sehat itu cara klasik mengundang bug datang bertamu.

---

## Konteks masalah

Di Android Settings, izin notifikasi app sudah ON.

Namun admin_web > Token Health masih menampilkan:

```text
Permission Blocked/Denied
```

Penyebab paling mungkin:

```text
1. permission_status token di Firestore/RTDB masih data lama.
2. App belum menulis ulang status izin setelah user mengaktifkan notifikasi dari Android Settings.
3. Token lama masih tampil di dashboard dan belum ditandai inactive.
4. registerDeviceToken hanya dipanggil pada momen tertentu, bukan saat app resume/Home dibuka.
```

Dashboard admin_web tidak membaca izin Android secara langsung. Dashboard hanya membaca field token di database, seperti:

```text
permission_status
active
updated_at
last_seen_at
permission_last_checked_at
```

Jadi app `mypresence` wajib melakukan resync token permission secara berkala.

---

## Keputusan yang tidak boleh diubah

Package Android final tetap:

```text
com.mypresence
```

Pastikan tetap:

```kotlin
namespace = "com.mypresence"
applicationId = "com.mypresence"
```

Jangan ubah:

```text
android/app/google-services.json
lib/firebase_options.dart
Firebase project config
package name
CameraPresencePage behavior
ProxyQrCameraPage behavior
PhotoQualityService behavior
HistoryPage logic 7 hari
ClockAttendanceCard behavior
RadiusCard behavior
NotificationRouter mapping utama
admin_web/cloud sender architecture
```

---

## Validasi wajib

Codex cukup menjalankan:

```bash
flutter analyze
```

Jangan menjalankan:

```bash
flutter build apk
flutter build appbundle
flutter run
flutter install
```

Build dan test device dilakukan manual oleh user.

---

# PATCH-01 - Tambahkan `refreshCurrentTokenStatus`

## Target file utama

```text
lib/services/push_notification_service.dart
```

## Instruksi

Tambahkan method public:

```dart
static Future<void> refreshCurrentTokenStatus(AppSession session) async
```

Method ini wajib:

```text
1. Panggil FirebaseMessaging.instance.getNotificationSettings().
2. Ambil FCM token saat ini dengan getToken().
3. Jika token kosong/null, tulis debug status empty_token dan permission terbaru.
4. Jika token tersedia, update Firestore token record.
5. Update RTDB mirror token record.
6. Update companies/{companyId}/users/{uid}/fcm_token_status.
```

Field yang harus diupdate di token record:

```text
token
token_id
platform
device_name
permission_status
statusbar_allowed
active
updated_at
last_seen_at
permission_last_checked_at
uid
company_id
app_source
```

Aturan `statusbar_allowed`:

```text
authorized atau provisional -> true
denied atau notDetermined -> false
```

Aturan `active`:

```text
authorized/provisional dan token tidak kosong -> true
denied/notDetermined atau token kosong -> false
```

Jika permission denied, tambahkan:

```text
invalid_reason = notification_permission_denied
```

Jika permission authorized/provisional, hapus/bersihkan `invalid_reason` jika sebelumnya berisi `notification_permission_denied`.

Jangan mematikan token karena error jaringan sementara.

## Catatan implementasi

Method ini sebaiknya memakai helper internal `_saveToken(...)` agar format path tetap sama.

Namun `_saveToken` sekarang menerima `permissionStatus` dari hasil requestPermission lama. Pastikan refresh membaca permission terbaru dari:

```dart
await _messaging.getNotificationSettings()
```

bukan memakai status lama yang tersimpan di closure token refresh.

## Acceptance criteria

- Saat user mengaktifkan izin notifikasi dari Android Settings lalu membuka app, token record berubah dari denied ke authorized.
- Token Health admin_web tidak lagi menampilkan permission blocked untuk token terbaru.
- Field `permission_last_checked_at` berubah saat refresh.
- `active` sesuai status permission terbaru.
- `flutter analyze` pass.

---

# PATCH-02 - Panggil Resync Saat Login/Home/App Resume

## Target file kemungkinan

```text
lib/main.dart
lib/features/auth/login_page.dart
lib/features/home/home_page.dart
lib/services/session_service.dart
lib/services/push_notification_service.dart
```

Sesuaikan dengan struktur repo.

## Instruksi

Panggil:

```dart
PushNotificationService.refreshCurrentTokenStatus(session)
```

pada momen berikut:

```text
1. Setelah login sukses dan session tersedia.
2. Saat HomePage initState/load awal.
3. Saat app resume dari background.
4. Setelah registerDeviceToken jika ada flow existing.
```

Untuk app resume, gunakan salah satu:

```text
WidgetsBindingObserver pada root app / MainShell / HomePage.
```

Saat lifecycle `AppLifecycleState.resumed`, panggil resync jika session valid.

## Jangan lakukan

```text
- Jangan memanggil requestPermission berulang-ulang di setiap frame.
- Jangan menampilkan dialog permission terus-menerus.
- Jangan logout user jika permission denied.
- Jangan mengganggu flow presensi.
```

Gunakan debounce ringan agar tidak spam write database.

Rekomendasi debounce:

```text
minimal 30-60 detik antar refresh token status
```

## Acceptance criteria

- Setelah user mengubah izin di Android Settings dan kembali ke app, status token tersinkron.
- Saat Home dibuka, token status tersinkron.
- Tidak ada spam write database tiap rebuild.
- `flutter analyze` pass.

---

# PATCH-03 - Perbaiki Token Refresh Listener agar Baca Permission Terbaru

## Target file

```text
lib/services/push_notification_service.dart
```

## Masalah

Listener `onTokenRefresh` bisa memakai permission status lama yang didapat saat `registerDeviceToken` pertama kali dipanggil.

## Instruksi

Di dalam listener:

```dart
_messaging.onTokenRefresh.listen((newToken) async { ... })
```

jangan pakai permission dari closure lama.

Ubah agar saat token refresh:

```dart
final latestSettings = await _messaging.getNotificationSettings();
await _saveToken(
  session,
  newToken,
  permissionStatus: latestSettings.authorizationStatus.name,
  preserveCreatedAt: true,
);
```

Pastikan field `statusbar_allowed`, `active`, dan `permission_last_checked_at` juga terupdate.

## Acceptance criteria

- Token baru selalu menyimpan permission terbaru.
- Token refresh tidak memakai permission status lama.
- `flutter analyze` pass.

---

# PATCH-04 - Tandai Token Lama Device yang Sama sebagai Inactive Jika Aman

## Target file

```text
lib/services/push_notification_service.dart
```

## Masalah

Token Health menampilkan banyak token lama untuk user yang sama. Ini membuat dashboard terlihat blocked/denied walaupun token terbaru sudah authorized.

## Instruksi

Saat menyimpan token baru yang valid:

```text
1. Ambil daftar token user di Firestore path existing.
2. Untuk token lain milik uid+companyId+platform yang sama, tandai inactive.
3. Jangan hapus token lama, cukup update active=false.
4. Mirror inactive ke RTDB juga.
```

Payload inactive token lama:

```text
active = false
updated_at = now
invalidated_at = now
invalid_reason = superseded_by_new_token
superseded_by = tokenId baru
```

Hati-hati:

```text
- Jangan menonaktifkan token device lain jika nanti multi-device ingin didukung.
- Jika tidak ada device_id stabil, batasi hanya token dengan platform yang sama dan app_source=mypresence.
- Jika ragu, buat method ini optional/aman, jangan sampai mematikan token device lain secara agresif.
```

## Acceptance criteria

- Token lama dari app/source yang sama tidak lagi terlihat active.
- Token terbaru tetap active.
- Token Health lebih bersih.
- `flutter analyze` pass.

---

# PATCH-05 - Tambahkan Helper untuk Membuka Settings Notifikasi Jika Permission Denied

## Target file kemungkinan

```text
lib/services/push_notification_service.dart
lib/features/profile/profile_page.dart
lib/features/notifications/notifications_page.dart
```

Opsional, tapi sangat berguna.

## Instruksi

Jika permission denied, app boleh menampilkan pesan ringan di halaman Profil atau Notifikasi:

```text
Notifikasi belum aktif. Aktifkan izin notifikasi agar reminder absen dan status pengajuan muncul di status bar.
```

Tambahkan tombol:

```text
Buka Pengaturan Notifikasi
```

Jika package untuk open app settings sudah ada, gunakan. Jika belum ada, jangan menambah dependency besar tanpa perlu. Cukup siapkan TODO ringan.

Jangan tampilkan popup paksa di Home setiap waktu.

## Acceptance criteria

- User diberi arahan jika permission denied.
- Tidak mengganggu flow absensi.
- `flutter analyze` pass.

---

# PATCH-06 - Tambahkan Debug Log Ringan di RTDB

## Target file

```text
lib/services/push_notification_service.dart
```

Saat refresh berhasil/gagal, update:

```text
companies/{companyId}/users/{uid}/fcm_token_status
```

Field minimal:

```text
status = registered / refreshed / empty_token / permission_denied / error
permission_status
statusbar_allowed
token_id
updated_at
platform
last_error
```

Jangan tulis token penuh di debug status. Token penuh cukup di token record.

## Acceptance criteria

- Admin bisa melihat status terakhir sync token.
- Debug status tidak mengekspos token penuh.
- `flutter analyze` pass.

---

# PATCH-07 - Manual Test Notes untuk Codex

Codex wajib menulis manual test di laporan akhir:

```text
1. Install build baru mypresence.
2. Login sebagai user target.
3. Buka Android Settings > App > MY PRESENCE > Izin aplikasi.
4. Pastikan Notifikasi ON.
5. Matikan 'Kelola aplikasi jika tidak digunakan' jika ada.
6. Buka app mypresence.
7. Masuk Home dan tunggu 5-10 detik.
8. Buka admin_web > Log Notifikasi > Kesehatan Token.
9. Klik Pindai Sembari Sinkron.
10. Pastikan token terbaru user menjadi ACTIVE dan permission bukan blocked/denied.
11. Kirim Uji Push dari admin_web.
12. Status bar harus muncul.
13. Jika belum muncul, cek delivery log dan permission_status terbaru.
```

---

# PATCH-08 - Jangan Ubah Area Lain

Jangan ubah:

```text
CameraPresencePage
ProxyQrCameraPage
PhotoQualityService
HistoryPage
ClockAttendanceCard
RadiusCard
Attendance submission logic
Admin_web integration payload
NotificationRouter mapping besar
```

Patch ini hanya untuk:

```text
FCM token permission resync
FCM token health cleanup
status debug token
```

---

# Laporan akhir wajib

Setelah selesai, Codex wajib menulis:

```text
## Summary
- Perubahan utama:
- File yang diubah:
- File baru:

## Token Permission Resync
- refreshCurrentTokenStatus:
- dipanggil saat login:
- dipanggil saat Home init:
- dipanggil saat app resume:
- debounce:

## Token Record Fields
- permission_status:
- statusbar_allowed:
- active:
- permission_last_checked_at:
- invalid_reason:

## Token Cleanup
- token lama inactive:
- RTDB mirror:

## Validation
- flutter analyze:

## Manual Build
- Tidak dijalankan oleh Codex. Build dilakukan manual oleh user.

## Manual Test Notes
- Langkah test ulang dengan admin_web:
```

---

# Urutan pengerjaan wajib

```text
1. Tambahkan refreshCurrentTokenStatus.
2. Update _saveToken agar mendukung statusbar_allowed, active by permission, permission_last_checked_at.
3. Ubah token refresh listener agar baca permission terbaru.
4. Panggil refresh setelah login/Home/app resume dengan debounce.
5. Tambahkan debug status RTDB.
6. Optional: inactive token lama secara aman.
7. flutter analyze.
8. Tulis laporan akhir.
```
