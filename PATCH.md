# PATCH.md - MYPRESENCE Flutter App

Dokumen ini adalah instruksi kerja untuk Codex pada repo `argajienbi/mypresence`.

Peran Codex: implementer teknis untuk Flutter app.
Peran ChatGPT: orkestrator, penjaga urutan kerja, validasi hasil, dan sinkronisasi dengan dashboard admin.

Jangan melakukan refactor besar, jangan mengganti stack, jangan mengganti package, dan jangan menghapus fitur yang sudah berjalan. Proyek ini butuh stabil, bukan aksi heroik yang berakhir dengan error merah seperti lampu rem truk.

---

## Keputusan penting yang tidak boleh diubah

### Package Android final

```text
com.mypresence
```

Codex wajib mempertahankan package ini.

Jangan ubah menjadi:

```text
com.my.presence
com.my.presensce
com.my.presensi
com.mypresensi
```

Repo saat ini memang memakai:

```kotlin
namespace = "com.mypresence"
applicationId = "com.mypresence"
```

Jadi tugas Codex bukan rename package, melainkan memastikan konfigurasi Firebase dan fitur QR/foto tetap konsisten dengan package tersebut.

---

## Prinsip kerja wajib

1. Kerjakan bertahap sesuai prioritas di bawah.
2. Jangan menghapus flow login, splash, home, history, profile, attendance selfie, QR, notification, schedule, atau service Firebase yang sudah ada.
3. Jangan mengganti struktur besar aplikasi tanpa kebutuhan jelas.
4. Jangan mengganti package Android dari `com.mypresence`.
5. Jika membuat file baru, pastikan import dan navigation lengkap.
6. Jangan membuat konfigurasi Firebase palsu.
7. Jangan commit secret baru, keystore, file credential pribadi, service account, `.env`, atau file rahasia lain.
8. Jalankan minimal:
   - `flutter pub get`
   - `flutter analyze`
   - build debug jika environment mendukung.
9. Jika ada error yang tidak bisa diselesaikan karena butuh file dari Firebase Console, berhenti dan tulis instruksi jelas di laporan akhir.

---

## Kondisi repo saat ini

Repo Flutter sudah memakai Firebase Core, Auth, RTDB, Storage, Firestore, FCM, local notification, geolocator, camera, QR scanner, QR generator, WebView, dan asset `assets/maps.html`.

Flow utama sudah ada:

- Firebase initialization di `lib/main.dart`.
- App root di `lib/app.dart`.
- Splash session loader di `lib/features/auth/splash_page.dart`.
- Session user di `lib/services/auth_service.dart`.
- Firebase path helper di `lib/core/firebase_paths.dart`.
- Attendance selfie di `lib/services/attendance_service.dart` dan `lib/features/attendance/camera_presence_page.dart`.
- QR titip absen di `lib/services/qr_service.dart` dan `lib/features/proxy_qr/proxy_attendance_page.dart`.
- Schedule resolver di `lib/services/schedule_service.dart`.
- Push notification di `lib/services/push_notification_service.dart`.

---

## PATCH-FLUTTER-01 - Validasi Firebase config tanpa rename package

### Masalah

Konfigurasi Firebase/Android perlu dicek agar tidak ada app id atau metadata lama yang bertentangan. Namun package Android final tetap `com.mypresence`.

### Target

Pastikan semua konfigurasi Android dan Firebase konsisten dengan package:

```text
com.mypresence
```

### File yang perlu dicek

- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/google-services.json`
- `lib/firebase_options.dart`
- `firebase.json`
- file Kotlin/Java native jika ada di bawah `android/app/src/main/kotlin` atau `android/app/src/main/java`

### Instruksi implementasi

1. Jangan ubah `namespace` dan `applicationId` jika sudah `com.mypresence`.
2. Cek `android/app/google-services.json` dan pastikan `client_info.android_client_info.package_name` adalah `com.mypresence`.
3. Cek `lib/firebase_options.dart` dan pastikan masih mengarah ke Firebase project yang sama dengan `google-services.json`.
4. Cek `firebase.json`. Jika ada Android app id lama/stale, jangan ubah package. Update hanya metadata FlutterFire yang memang tidak cocok, atau tulis catatan bila harus regenerate lewat FlutterFire CLI.
5. Jangan membuat app id Firebase palsu secara manual.
6. Pastikan `flutter analyze` tidak error.

### Acceptance criteria

- `namespace` tetap `com.mypresence`.
- `applicationId` tetap `com.mypresence`.
- `google-services.json` cocok dengan `com.mypresence`.
- Tidak ada instruksi rename package.
- Jika butuh regenerate config Firebase, laporan akhir menyebut langkah manual yang diperlukan.

---

## PATCH-FLUTTER-02 - QR titip absen wajib foto sebelum request admin

### Masalah

Flow QR titip absen saat ini:

```text
scan QR -> validasi target -> pilih masuk/pulang -> kirim request admin
```

Belum ada langkah ambil foto setelah QR valid.

### Target flow baru

```text
scan QR -> validasi target -> pilih masuk/pulang -> ambil foto -> upload foto -> buat request admin
```

QR dipakai ketika karyawan lupa membawa HP. Helper scan QR milik target, lalu harus mengambil foto sebagai bukti sebelum request masuk ke admin.

### File utama

- `lib/features/proxy_qr/proxy_attendance_page.dart`
- `lib/services/qr_service.dart`
- `lib/core/firebase_paths.dart`
- `lib/services/storage_service.dart`
- Bisa membuat file baru, misalnya:
  - `lib/features/proxy_qr/proxy_qr_camera_page.dart`

### Instruksi implementasi

1. Setelah QR valid dan user memilih `Masuk` atau `Pulang`, tombol jangan langsung membuat request.
2. Ubah tombol menjadi aksi lanjut ke halaman kamera.
3. Buat halaman kamera khusus QR atau reuse logic kamera yang aman dari `CameraPresencePage`.
4. Setelah foto diambil, upload foto ke Firebase Storage.
5. Gunakan path Storage yang sudah tersedia atau tambahkan helper bila perlu:

```dart
FirebasePaths.qrAttendancePhoto(companyId, targetUid, date, actionType, ts)
```

6. Simpan hasil upload ke request QR:

```text
photo_url
photo_path
```

7. Request QR tetap disimpan ke:

```text
qr_attendance_requests/{companyId}/{requestId}
```

8. Jangan buat request admin tanpa foto, kecuali kamera benar-benar gagal dan user membatalkan proses.
9. Tambahkan field audit yang jelas:

```text
method: qr
source: mobile_app
status: pending
attendance_status: pending_admin
helper_uid
helper_name
target_uid
target_name
created_by_qr atau field equivalent jika memang digunakan di request
```

10. Pastikan admin web tetap bisa membaca `photo_url` dan `photo_path` dari QR request.

### UX minimal

- Setelah QR valid, tampilkan nama target dan NIP.
- Tombol: `Lanjut Ambil Foto`.
- Setelah foto berhasil: preview foto.
- Tombol submit: `Kirim Request Admin`.
- Setelah sukses: kembali ke halaman sebelumnya dengan toast sukses.

### Acceptance criteria

- Request QR tidak terkirim sebelum foto diambil.
- Admin web menerima `photo_url` dan `photo_path`.
- Helper tidak bisa scan QR sendiri.
- Company berbeda tetap ditolak.
- QR inactive/token mismatch tetap ditolak.
- Location/geofence helper tetap dicek.
- `flutter analyze` tidak error.

---

## PATCH-FLUTTER-03 - Validasi regression attendance selfie

### Target

Pastikan perubahan QR tidak merusak attendance selfie reguler.

### Cek wajib

- Login user active.
- Load session dari `/users/{uid}` dan `/company_users/{companyId}/{uid}`.
- Home menampilkan status hari ini.
- Absen masuk selfie tetap menyimpan ke:

```text
attendance/{companyId}/{uid}/{date}/masuk
```

- Absen pulang selfie tetap menyimpan ke:

```text
attendance/{companyId}/{uid}/{date}/pulang
```

- Field penting tetap ada:

```text
company_id
uid
user_name
nip
date
time
action_type
method
source
status
attendance_status
photo_url
photo_path
latitude
longitude
distance_meter
radius_meter
geofence_status
office_id
department_id
sub_department_id
group_id
created_by_qr
validation_status
created_at
updated_at
```

---

## PATCH-FLUTTER-04 - Release signing, hanya rapikan jika belum valid

### Catatan status

Jika `android/app/build.gradle.kts` sudah memakai `key.properties` dan fallback debug signing saat key belum ada, jangan rewrite total. Cukup validasi dan rapikan bagian yang kurang.

### Target

Siapkan konfigurasi release signing tanpa mengupload file rahasia.

### Instruksi

1. Tambahkan template `key.properties.example` jika belum ada.
2. Update `.gitignore` agar file berikut tidak masuk repo:

```text
key.properties
*.jks
*.keystore
```

3. Pastikan `build.gradle.kts` membaca dari `key.properties` jika tersedia.
4. Pastikan debug build tetap bisa jalan ketika `key.properties` belum ada.
5. Jangan membuat atau commit keystore asli.

### Acceptance criteria

- Debug build tetap jalan.
- Release build bisa dikonfigurasi oleh user lokal.
- Tidak ada secret masuk repo.
- Package tetap `com.mypresence`.

---

## Laporan akhir yang wajib diberikan Codex

Setelah mengerjakan, buat ringkasan:

```text
## Summary
- Perubahan utama:
- File yang diubah:
- File baru:

## Validation
- flutter pub get: pass/fail
- flutter analyze: pass/fail
- build debug: pass/fail/not run

## Package Check
- namespace:
- applicationId:
- google-services package:

## Notes
- Hal yang butuh tindakan user:
- Risiko yang tersisa:
```

---

## Urutan pengerjaan

Kerjakan berurutan:

1. PATCH-FLUTTER-01
2. PATCH-FLUTTER-02
3. PATCH-FLUTTER-03
4. PATCH-FLUTTER-04

Jangan rename package. Jangan mulai dari redesign UI. Jangan melakukan perubahan besar di luar daftar ini.
