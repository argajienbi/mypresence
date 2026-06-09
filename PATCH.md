# PATCH.md - MYPRESENCE Flutter App

Dokumen ini adalah instruksi kerja untuk Codex pada repo `argajienbi/mypresence`.

Peran Codex: implementer teknis untuk Flutter app.
Peran orkestrator: ChatGPT akan menjaga urutan kerja, validasi hasil, dan sinkronisasi dengan dashboard admin.

Jangan mengubah fitur yang sudah berjalan tanpa alasan kuat. Jangan refactor besar-besaran hanya karena ingin terlihat pintar. Proyek ini butuh stabil, bukan atraksi sulap kode.

---

## Prinsip kerja wajib

1. Kerjakan bertahap sesuai prioritas di bawah.
2. Jangan menghapus flow login, splash, home, history, profile, attendance selfie, QR, notification, schedule, atau service Firebase yang sudah ada.
3. Jangan mengganti struktur besar aplikasi tanpa kebutuhan jelas.
4. Jika membuat file baru, pastikan import dan route/page navigation lengkap.
5. Setiap perubahan harus bisa dijelaskan di akhir pekerjaan.
6. Jangan membuat konfigurasi Firebase palsu.
7. Jangan commit secret baru, keystore, file credential pribadi, atau service account.
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

## PATCH-FLUTTER-01 - Normalisasi package dan Firebase config

### Masalah

Ada indikasi konfigurasi Android/Firebase tidak konsisten:

- `android/app/build.gradle.kts` memakai package/app id `com.mypresence`.
- `android/app/google-services.json` memakai package `com.mypresence`.
- `lib/firebase_options.dart` memakai Firebase project `inventory-410f4`.
- `firebase.json` bisa berisi app id Android lama yang berbeda.

### Target

Pastikan semua konfigurasi Android dan Firebase konsisten.

### Keputusan package

Gunakan package final:

```text
com.my.presence
```

Catatan: jangan gunakan `com.my.presensce` karena itu typo. Jika project Firebase belum punya Android app untuk `com.my.presence`, jangan memalsukan `google-services.json`. Buat catatan bahwa user harus membuat Android app baru di Firebase Console dan mengunduh file config baru.

### File yang perlu dicek atau diubah

- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/google-services.json`
- `lib/firebase_options.dart`
- `firebase.json`
- package namespace Android native jika ada file Kotlin/Java di bawah `android/app/src/main/kotlin` atau `android/app/src/main/java`

### Instruksi implementasi

1. Ubah `namespace` dan `applicationId` menjadi `com.my.presence`.
2. Cek apakah `google-services.json` sudah cocok dengan package `com.my.presence`.
3. Jika belum cocok, jangan edit manual app id Firebase secara asal. Laporkan bahwa file harus digenerate ulang dari Firebase Console atau FlutterFire CLI.
4. Cek `firebase.json`. Pastikan app id Android tidak stale.
5. Jika `firebase_options.dart` perlu digenerate ulang, lakukan hanya jika Firebase CLI/FlutterFire tersedia dan konfigurasi valid.
6. Pastikan app masih bisa dianalisis dengan `flutter analyze`.

### Acceptance criteria

- `applicationId` final jelas.
- Tidak ada dua package Android yang berbeda.
- Tidak ada app id Firebase yang saling bertentangan.
- Build/debug tidak rusak karena package rename.
- Jika butuh file Firebase baru dari user, laporan akhir harus menyebut file yang dibutuhkan.

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
created_by_qr: true atau equivalent jika memang digunakan di request
```

10. Pastikan admin web tetap bisa membaca `photo_url` dan `photo_path` dari QR request.

### UX minimal

- Setelah QR valid, tampilkan nama target dan NIP.
- Tombol: `Lanjut Ambil Foto`.
- Setelah foto berhasil: preview foto.
- Tombol submit: `Kirim Request Admin`.
- Setelah sukses: kembali ke home atau halaman sebelumnya dengan toast sukses.

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

## PATCH-FLUTTER-04 - Release signing, jangan dikerjakan sebelum config stabil

Tahap ini jangan dikerjakan sebelum PATCH-FLUTTER-01 dan PATCH-FLUTTER-02 selesai.

### Masalah

Release build masih memakai debug signing.

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

3. Update `build.gradle.kts` agar release signing membaca dari `key.properties` jika tersedia.
4. Jangan membuat atau commit keystore asli.

### Acceptance criteria

- Debug build tetap jalan.
- Release build bisa dikonfigurasi oleh user lokal.
- Tidak ada secret masuk repo.

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

Jangan lompat ke release signing sebelum QR dan Firebase config stabil.
