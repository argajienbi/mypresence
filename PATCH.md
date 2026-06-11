# PATCH.md - MYPRESENCE Notification & Attendance Reminder Polish

Dokumen ini adalah instruksi kerja untuk Codex pada repo `argajienbi/mypresence`.

Patch sebelumnya untuk single attendance card, refresh foto profil, back behavior, dan maps card sudah dianggap selesai. Jangan sentuh lagi kecuali ada error compile langsung.

Fokus patch ini hanya:

```text
1. Hapus banner approval cuti/izin/sakit dari Home.
2. Pastikan approval pengajuan muncul di icon bell sebagai notifikasi singkat.
3. Pastikan klik notifikasi approval mengarah ke Status Pengajuan/detail pengajuan yang relevan.
4. Audit dan validasi trigger notifikasi status bar saat sudah/waktunya absen sesuai jadwal.
```

Jangan mengubah package, Firebase config, struktur RTDB utama, logic absensi yang sudah berjalan, kamera, history 7 hari, maps card, atau single attendance card. Kita sedang merapikan distribusi notifikasi, bukan mengadakan migrasi peradaban kecil-kecilan.

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
CameraPresencePage behavior yang sudah diperbaiki
ProxyQrCameraPage behavior yang sudah diperbaiki
PhotoQualityService compress/resize yang sudah berjalan
HistoryPage logic 7 hari yang sudah berjalan
ClockAttendanceCard single dynamic card yang sudah berjalan
RadiusCard clickable/detail lokasi yang sudah berjalan
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

Build dan test notifikasi di device akan dilakukan manual oleh user.

---

# PATCH-01 - Hapus Banner Approved Leave dari Home

## Masalah

Saat pengajuan cuti/izin/sakit disetujui hari ini, Home menampilkan banner besar seperti:

```text
Cuti Disetujui Hari Ini
Cuti tahunan
```

User ingin informasi approval seperti ini muncul di icon bell/notifikasi dan halaman Status Pengajuan, bukan sebagai banner besar di Home.

## File target utama

```text
lib/features/home/home_page.dart
```

## Instruksi implementasi

1. Hapus tampilan `_ApprovedLeaveBanner` dari body Home.
2. Jangan tampilkan banner approval cuti/izin/sakit/lembur di Home.
3. Home tetap fokus pada:

```text
- Lokasi & Radius Absensi
- Tombol Absen
- Menu Cepat
- Pengumuman
```

4. Jangan hapus logic `_approvedLeaveToday` sepenuhnya jika masih dipakai untuk validasi absensi.
5. Logic validasi tetap:

```text
Jika hari ini ada cuti/izin/sakit yang sudah disetujui, user tidak wajib absen dan tidak langsung diarahkan ke selfie presensi.
```

6. Jika `_ApprovedLeaveBanner` tidak lagi dipakai di file mana pun, boleh hapus class widget-nya agar tidak jadi kode mati.

## Acceptance criteria

- Home tidak lagi menampilkan banner “Cuti/Izin/Sakit Disetujui Hari Ini”.
- User dengan cuti/izin/sakit disetujui tetap tidak dipaksa absen.
- Status lengkap tetap tersedia di Status Pengajuan.
- Notifikasi singkat approval tetap tersedia di icon bell.
- `flutter analyze` pass.

---

# PATCH-02 - Approval Pengajuan Tetap Masuk Icon Bell sebagai Notifikasi Singkat

## Kondisi saat ini

Halaman Notifikasi sudah membaca dua sumber:

```text
Firestore notification inbox
RTDB notifications/{uid}
```

Filter Notifikasi juga sudah punya kategori:

```text
Semua
Belum dibaca
Approval
Jadwal
Koreksi
Presensi
Sistem
```

Approval pengajuan seharusnya tampil sebagai notifikasi singkat di icon bell, sementara detail lengkap tetap ada di halaman Status Pengajuan.

## File target kemungkinan

```text
lib/services/app_notification_service.dart
lib/features/notifications/notifications_page.dart
lib/features/notifications/notification_detail_page.dart
lib/services/notification_router.dart
lib/features/requests/request_status_page.dart
lib/features/requests/request_status_detail_sheet.dart
```

Jika pembuatan notifikasi approval berasal dari admin_web/backend, jangan ubah schema secara asal. Cukup pastikan app Flutter bisa membaca dan mengarahkan dengan benar.

## Aturan UX

Jangan membuat duplikasi penuh.

Pembagian yang benar:

```text
Home = tidak menampilkan banner approval.
Icon Bell = notifikasi singkat bahwa status pengajuan berubah.
Status Pengajuan = data lengkap dan riwayat pengajuan.
```

Contoh notifikasi bell:

```text
Cuti Disetujui
Pengajuan cuti Anda pada 8 Jun 2026 - 12 Jun 2026 telah disetujui.
```

Atau:

```text
Izin Ditolak
Pengajuan izin Anda ditolak. Lihat detail catatan admin.
```

## Instruksi implementasi

1. Pastikan item approval dengan kata/ref berikut masuk filter personal notification:

```text
approval
approved
rejected
leave
izin
cuti
sakit
lembur
overtime
correction
koreksi
qr
attendance
presensi
```

2. Pastikan notifikasi approval tidak dianggap pengumuman umum.
3. Pastikan filter `Approval` menangkap:

```text
izin
sakit
cuti
lembur
leave
overtime
approved
rejected
approval
```

4. Jangan tampilkan data detail lengkap pengajuan di list notifikasi. List cukup ringkas.
5. Detail penuh tetap dibuka dari Status Pengajuan/detail pengajuan.

## Acceptance criteria

- Approval cuti/izin/sakit/lembur tampil di filter `Approval` pada halaman Notifikasi jika datanya memang ada di Firestore/RTDB inbox.
- Bell badge menghitung unread approval sebagai personal notification.
- Pengumuman umum tetap tidak dihitung sebagai personal approval.
- Tidak ada banner approval di Home.
- `flutter analyze` pass.

---

# PATCH-03 - Klik Notifikasi Approval Harus Mengarah ke Status Pengajuan

## Masalah

Saat ini routing notifikasi dengan `ref_type` mengandung `leave` atau `approval` berpotensi diarahkan ke `MainShell(initialIndex: 0)`, yaitu tab Riwayat. Ini kurang tepat.

Approval pengajuan harus mengarah ke halaman Status Pengajuan atau detail pengajuan terkait.

## File target utama

```text
lib/services/notification_router.dart
```

Target tambahan jika perlu:

```text
lib/features/profile/profile_page.dart
lib/features/requests/request_status_page.dart
lib/features/requests/request_status_detail_sheet.dart
```

## Instruksi implementasi

1. Ubah routing untuk notifikasi approval/leave/izin/cuti/sakit/lembur/koreksi agar menuju Status Pengajuan.
2. Jika `RequestStatusPage` bisa menerima filter/initial ref, tambahkan parameter opsional:

```dart
initialStatus
initialType
highlightRefId
```

3. Jika detail langsung belum mudah, minimal arahkan ke halaman Status Pengajuan, bukan Riwayat.
4. Jika `ref_id` tersedia, gunakan untuk highlight atau membuka detail terkait.
5. Jangan membuat route baru yang merusak navigation utama.

## Mapping rekomendasi

```text
ref_type contains leave/izin/cuti/sakit/lembur/approval -> RequestStatusPage
ref_type contains correction/koreksi -> RequestStatusPage filter koreksi
ref_type contains qr -> RequestStatusPage atau detail QR request jika tersedia
ref_type contains attendance/presensi -> Riwayat/Detail Presensi
ref_type contains schedule/jadwal -> Home + detail jadwal
ref_type contains announcement/pengumuman -> Pengumuman
```

## Acceptance criteria

- Klik notifikasi cuti/izin/sakit disetujui membuka Status Pengajuan/detail pengajuan.
- Klik notifikasi approval tidak lagi hanya membuka tab Riwayat.
- Tombol `Lihat Detail Pengajuan` di `NotificationDetailPage` mengarah ke tempat yang benar.
- Jika ref id tidak ditemukan, fallback tetap aman ke Status Pengajuan.
- `flutter analyze` pass.

---

# PATCH-04 - Audit Trigger Notifikasi Status Bar Saat Waktu Absen Sesuai Jadwal

## Masalah

User belum mengetes apakah alert/notifikasi status bar muncul saat sudah masuk waktu absen sesuai jadwal.

Saat ini service reminder perlu diaudit agar jelas:

```text
- kapan notifikasi dijadwalkan
- apakah muncul di status bar Android
- apakah masuk icon bell/inbox
- apakah tap notification membuka halaman yang tepat
```

## File target utama

```text
lib/services/attendance_reminder_service.dart
lib/services/local_notification_service.dart
lib/features/home/home_page.dart
lib/services/notification_router.dart
AndroidManifest.xml jika izin notifikasi/exact alarm perlu dicek
```

## Kondisi yang perlu diperiksa

Dari logic sekarang, reminder kemungkinan dijadwalkan:

```text
- 10 menit sebelum jam kerja mulai untuk absen masuk
- 10 menit sebelum jam kerja selesai untuk absen pulang
```

Codex harus memastikan apakah kebutuhan final adalah:

```text
A. Notifikasi 10 menit sebelum waktu absen
B. Notifikasi tepat saat jam absen dimulai
C. Keduanya
```

Untuk sekarang, jangan mengubah drastis tanpa perlu. Minimal audit dan pastikan notifikasi 10 menit sebelum berjalan. Jika mudah dan aman, tambahkan notifikasi tepat waktu dengan ID berbeda.

## Instruksi implementasi

1. Pastikan local notification sudah initialize saat app start.
2. Pastikan permission notifikasi Android 13+ (`POST_NOTIFICATIONS`) diminta/ditangani.
3. Pastikan notification channel high importance dibuat.
4. Pastikan scheduled notification memakai payload yang benar:

```text
ref_type: attendance_reminder
reminder_action: check_in / check_out
```

5. Pastikan notifikasi juga tercatat di RTDB `notifications/{uid}` agar muncul di icon bell.
6. Pastikan reminder tidak muncul jika:

```text
- hari libur
- bukan workday
- user sudah absen masuk untuk check_in
- user sudah absen pulang untuk check_out
- user punya izin/sakit/cuti disetujui hari ini
```

7. Pastikan saat user selesai absen, reminder lama dibersihkan/ditandai inactive/read.
8. Pastikan tap notifikasi attendance reminder membuka Home, bukan halaman kosong.
9. Jika menggunakan `inexactAllowWhileIdle`, catat bahwa waktu muncul bisa tidak presisi penuh di beberapa device Android. Jangan klaim exact alarm kecuali memakai exact scheduling dan izin yang sesuai.

## Optional improvement jika aman

Tambahkan dua tahap reminder:

```text
check_in_pre   -> 10 menit sebelum jam masuk
check_in_now   -> tepat saat jam masuk/checkInStart
check_out_pre  -> 10 menit sebelum jam pulang
check_out_now  -> tepat saat jam pulang/checkOutStart atau workEnd sesuai logic jadwal
```

Gunakan notification ID berbeda agar tidak saling overwrite.

Namun jika perubahan ini berisiko besar, cukup audit dan rapikan existing reminder dulu.

## Acceptance criteria

- Reminder absen masuk dijadwalkan sesuai jadwal user.
- Reminder absen pulang dijadwalkan sesuai jadwal user.
- Status bar Android menampilkan notifikasi saat waktunya tiba.
- Notifikasi masuk ke icon bell/inbox sebagai personal notification.
- Tap notifikasi membuka Home atau flow presensi yang relevan.
- Reminder tidak muncul setelah user sudah melakukan aksi terkait.
- Reminder tidak muncul saat user punya cuti/izin/sakit disetujui hari ini.
- `flutter analyze` pass.

## Catatan manual test untuk user

Codex wajib menulis catatan manual test seperti ini di laporan akhir:

```text
Manual test reminder:
1. Buat jadwal hari ini dengan jam masuk 5-15 menit dari waktu sekarang.
2. Login ke app dan buka Home agar reminder terschedule.
3. Pastikan permission notifikasi aktif.
4. Kunci/minimize app.
5. Tunggu sampai waktu reminder.
6. Cek status bar Android.
7. Tap notifikasi dan pastikan membuka Home.
8. Cek icon bell, reminder harus muncul sebagai personal notification.
9. Lakukan absen masuk, lalu pastikan reminder masuk tidak muncul lagi.
```

---

# File yang jangan disentuh kecuali terpaksa

```text
lib/features/attendance/camera_presence_page.dart
lib/features/proxy_qr/proxy_qr_camera_page.dart
lib/services/photo_quality_service.dart
lib/features/history/history_page.dart
lib/features/home/widgets/clock_attendance_card.dart
lib/features/home/widgets/radius_card.dart
lib/features/home/widgets/location_detail_sheet.dart
android/app/build.gradle
android/app/google-services.json
lib/firebase_options.dart
```

---

# Laporan akhir Codex

Setelah selesai, Codex wajib menulis laporan:

```text
## Summary
- Perubahan utama:
- File yang diubah:
- File baru:

## Validation
- flutter analyze: pass/fail

## Notification Routing Check
- Approval notification route:
- Attendance reminder route:
- Bell inbox source:

## Manual Build
- Tidak dijalankan oleh Codex. Build dilakukan manual oleh user.

## Manual Test Notes
- Cara test reminder status bar:
- Risiko Android permission/battery optimization:

## Notes
- Apakah kamera/history/card absen/maps tidak disentuh:
- Risiko tersisa:
```

Jangan menulis hasil build karena build tidak diminta.

---

# Urutan pengerjaan wajib

```text
1. Hapus banner approved leave dari Home tanpa menghapus validasi cuti/izin/sakit.
2. Audit filter personal notification dan approval di icon bell.
3. Perbaiki routing klik approval ke Status Pengajuan/detail pengajuan.
4. Audit scheduled attendance reminder ke status bar dan icon bell.
5. flutter analyze.
6. Tulis laporan akhir lengkap dengan catatan manual test.
```
