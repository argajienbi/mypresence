# PATCH.md - MYPRESENCE FCM Lifecycle Resync Wiring

Dokumen ini adalah instruksi kerja untuk Codex pada repo `argajienbi/mypresence`.

Fokus patch ini **hanya menyambungkan** method yang sudah dibuat:

```dart
PushNotificationService.refreshCurrentTokenStatus(session)
```

ke lifecycle aplikasi, supaya status izin notifikasi/token FCM benar-benar tersinkron saat user membuka app, masuk Home, login ulang, atau kembali dari Android Settings.

Patch sebelumnya sudah menambahkan inti penyimpanan token seperti:

```text
refreshCurrentTokenStatus
statusbar_allowed
permission_last_checked_at
active berdasarkan permission
invalid_reason notification_permission_denied
superseded_by_new_token
fcm_token_status debug
```

Namun dari audit repo, method refresh sudah ada tetapi belum jelas dipanggil dari Home/Login/App Resume. Method bagus yang tidak dipanggil itu cuma pajangan kode, seperti tombol lift palsu yang membuat manusia merasa punya kendali.

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
CameraPresencePage
ProxyQrCameraPage
PhotoQualityService
HistoryPage
ClockAttendanceCard
RadiusCard
Attendance submission logic
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

# PATCH-01 - Panggil Refresh Setelah Login Sukses

## Target file kemungkinan

Cari flow login/session di file seperti:

```text
lib/features/auth/login_page.dart
lib/features/auth/login_controller.dart
lib/features/login/login_page.dart
lib/services/auth_service.dart
lib/services/session_service.dart
lib/main.dart
```

Sesuaikan dengan struktur repo yang sebenarnya.

## Instruksi

Setelah login sukses dan `AppSession` sudah tersedia, panggil:

```dart
unawaited(PushNotificationService.refreshCurrentTokenStatus(session, force: true));
```

Jika file belum import `dart:async`, tambahkan:

```dart
import 'dart:async';
```

Jika `unawaited` tidak tersedia/kurang cocok, boleh gunakan:

```dart
PushNotificationService.refreshCurrentTokenStatus(session, force: true).catchError((_) {});
```

## Syarat penting

Jangan panggil sebelum `session.companyId` dan `session.uid` valid.

Jangan mengganggu navigasi login ke Home.

Jangan menjadikan kegagalan refresh token sebagai alasan login gagal.

## Acceptance criteria

- Setelah login ulang, token status langsung refresh.
- Jika Android notification permission sudah ON, database token menjadi `statusbar_allowed=true` dan `active=true`.
- Login tetap sukses walaupun refresh token gagal karena jaringan.
- `flutter analyze` pass.

---

# PATCH-02 - Panggil Refresh Saat Home Dibuka

## Target file kemungkinan

```text
lib/features/home/home_page.dart
lib/features/home/home_screen.dart
lib/features/home/presentation/home_page.dart
```

## Instruksi

Saat HomePage `initState` atau load awal dan session valid, panggil:

```dart
unawaited(PushNotificationService.refreshCurrentTokenStatus(session));
```

Jika Home punya method load seperti:

```dart
_loadData()
_loadHome()
_initializeHome()
```

boleh panggil di akhir load awal, asalkan tidak dipanggil setiap rebuild.

## Jangan lakukan

```text
- Jangan panggil di build().
- Jangan panggil dalam stream builder/list builder yang sering rebuild.
- Jangan refresh berulang tiap detik.
```

`refreshCurrentTokenStatus` sudah punya debounce 45 detik, tetapi tetap jangan dipanggil sembarangan seperti bel rumah rusak.

## Acceptance criteria

- Saat user buka Home, `permission_last_checked_at` update.
- Token Health admin_web membaca token terbaru.
- Tidak ada spam write Firestore/RTDB.
- `flutter analyze` pass.

---

# PATCH-03 - Panggil Refresh Saat App Resume

## Target file kemungkinan

Pilih tempat paling aman:

```text
lib/main.dart
lib/app.dart
lib/features/home/home_page.dart
lib/features/main/main_shell.dart
lib/features/root/root_page.dart
```

## Instruksi

Gunakan `WidgetsBindingObserver` pada widget yang hidup selama user berada di area utama app.

Contoh pola implementasi:

```dart
class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshFcmTokenStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshFcmTokenStatus();
    }
  }

  void _refreshFcmTokenStatus() {
    final session = ...; // ambil session existing dari state/service yang sudah ada
    if (session == null) return;
    unawaited(PushNotificationService.refreshCurrentTokenStatus(session));
  }
}
```

Kalau widget root sudah punya lifecycle observer, gunakan yang existing. Jangan bikin observer dobel di banyak halaman jika ada MainShell/root yang lebih tepat.

## Kenapa ini wajib

Saat user membuka Android Settings lalu mengaktifkan Notifikasi, app perlu refresh saat user kembali ke app. Tanpa lifecycle resume, dashboard admin bisa tetap membaca status lama. Manusia sudah menekan izin, database masih belum tahu. Peradaban modern, katanya.

## Acceptance criteria

- Setelah user ON-kan notifikasi di Android Settings lalu kembali ke app, status token tersinkron tanpa perlu logout.
- `permission_last_checked_at` berubah.
- `statusbar_allowed` berubah sesuai permission terbaru.
- Observer dibersihkan di dispose.
- `flutter analyze` pass.

---

# PATCH-04 - Pastikan Permission Prompt Awal Tetap Aman

## Target file

```text
lib/services/push_notification_service.dart
```

## Masalah yang perlu dicek

`registerDeviceToken()` sekarang membaca permission dengan:

```dart
getNotificationSettings()
```

Ini bagus untuk resync, tetapi untuk install pertama, permission bisa masih:

```text
notDetermined
```

Jika tidak pernah memanggil `requestPermission()`, user tidak akan diberi popup izin notifikasi.

## Instruksi

Di `registerDeviceToken`, gunakan pola aman:

```dart
var settings = await _messaging.getNotificationSettings();

if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
  settings = await _messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );
}
```

Jangan panggil `requestPermission()` jika status sudah `denied`, `authorized`, atau `provisional`.

Untuk user yang `denied`, arahkan lewat `openNotificationSettings()` jika UI sudah ada. Jangan spam popup, karena Android tidak akan terkesan dengan permohonan berulang dari aplikasi absensi.

## Acceptance criteria

- Install pertama tetap bisa memunculkan prompt izin notifikasi.
- User yang sudah denied tidak diganggu popup terus-menerus.
- Resync tetap membaca permission terbaru.
- `flutter analyze` pass.

---

# PATCH-05 - Pastikan Import dan Error Handling Aman

## Target file

Semua file yang memanggil refresh.

## Instruksi

Jika memakai `unawaited`, pastikan import:

```dart
import 'dart:async';
```

Pastikan import service:

```dart
import '../../services/push_notification_service.dart';
```

atau path yang benar sesuai lokasi file.

Semua refresh harus non-blocking:

```dart
unawaited(PushNotificationService.refreshCurrentTokenStatus(session));
```

Jangan sampai error refresh membuat halaman gagal tampil.

## Acceptance criteria

- Tidak ada unused import.
- Tidak ada compile error karena path import salah.
- `flutter analyze` pass.

---

# PATCH-06 - Manual Test Wajib

Codex wajib menulis catatan manual test:

```text
1. Install build baru mypresence.
2. Login sebagai user target.
3. Buka Home dan tunggu 5-10 detik.
4. Buka admin_web > Log Notifikasi > Kesehatan Token.
5. Klik Refresh Token Health.
6. Pastikan token current menjadi ACTIVE dan Permission OK.
7. Matikan izin notifikasi dari Android Settings.
8. Kembali ke app mypresence.
9. Cek permission_last_checked_at berubah dan statusbar_allowed=false.
10. Nyalakan lagi izin notifikasi dari Android Settings.
11. Kembali ke app mypresence.
12. Cek permission_last_checked_at berubah dan statusbar_allowed=true.
13. Kirim Uji Push dari admin_web.
14. Status bar harus muncul.
```

---

# PATCH-07 - Jangan Ubah Area Lain

Patch ini hanya untuk lifecycle wiring FCM token refresh.

Jangan ubah:

```text
UI Home kecuali penambahan lifecycle call kecil
kamera absen
history
maps
clock card
approval pages
notification routing besar
attendance submission
photo upload/compression
```

Kalau harus menyentuh HomePage, perubahan hanya:

```text
- tambah WidgetsBindingObserver jika belum ada
- tambah helper kecil _refreshFcmTokenStatus
- panggil refresh di initState/resume
```

---

# Laporan akhir wajib

Setelah selesai, Codex wajib menulis:

```text
## Summary
- Perubahan utama:
- File yang diubah:
- File baru:

## Lifecycle Wiring
- Setelah login:
- Home init/load:
- App resume:

## Permission Prompt
- notDetermined handling:
- denied handling:

## Validation
- flutter analyze:

## Manual Build
- Tidak dijalankan oleh Codex. Build dilakukan manual oleh user.

## Manual Test Notes
- Cara test dengan admin_web Token Health:
- Cara test Uji Push:
```

---

# Urutan pengerjaan wajib

```text
1. Cari flow login/session.
2. Panggil refresh setelah login sukses.
3. Cari HomePage/MainShell/root lifecycle.
4. Panggil refresh saat Home init/load awal.
5. Tambahkan WidgetsBindingObserver untuk app resume.
6. Pastikan registerDeviceToken tetap requestPermission hanya saat notDetermined.
7. Pastikan semua refresh non-blocking dan tidak membuat UI gagal.
8. flutter analyze.
9. Tulis laporan akhir.
```
