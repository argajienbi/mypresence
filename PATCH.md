# PATCH.md - MYPRESENCE FCM Receiver & Local Fallback Cleanup

Dokumen ini adalah instruksi kerja untuk Codex pada repo `argajienbi/mypresence`.

Patch sebelumnya untuk single attendance card, refresh foto profil, back behavior, maps card, approval routing, dan local attendance reminder sudah dianggap selesai. Jangan sentuh lagi kecuali ada error compile langsung.

Fokus patch ini hanya memastikan `mypresence` siap sebagai **penerima notifikasi FCM** dan menjaga local notification sebagai fallback. Pengiriman FCM utama untuk event bisnis harus dikerjakan di `admin_web`/cloud/backend, bukan di app Flutter.

---

## Konteks penting

Test push FCM dari admin sudah normal. Artinya device/app penerima sudah bisa menerima FCM.

Masalah yang tersisa:

```text
- Notifikasi bell/inbox masuk.
- Tetapi perubahan jadwal/reminder kadang tidak muncul di status bar.
```

Kesimpulan arsitektur:

```text
admin_web/cloud/backend = pengirim resmi event bisnis via FCM
mypresence = penerima FCM + pembaca inbox/bell + fallback local notification
```

Jangan mencoba mengirim FCM dari app Flutter menggunakan server key. Itu berbahaya dan tidak boleh dilakukan. App Flutter hanya menyimpan token dan menerima payload.

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
Profile photo refresh yang sudah berjalan
Back behavior yang sudah berjalan
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

Build dan test notifikasi di device dilakukan manual oleh user.

---

# PATCH-01 - Rapikan Receiver Payload FCM

## Target file

```text
lib/services/push_notification_service.dart
lib/services/notification_router.dart
lib/features/notifications/notifications_page.dart
lib/features/notifications/notification_detail_page.dart
```

## Instruksi

Pastikan app bisa membaca payload dari admin_web/cloud dengan field standar berikut:

```text
notification_id
id
inbox_id
company_id
uid
title
body
message
type
ref_type
ref_id
related_id
sender_uid
sender_name
sender_role
created_at
```

Jika sebagian field kosong, lakukan fallback aman:

```text
notification_id fallback ke id/inbox_id/messageId
body fallback ke message/notification_body
type fallback ke info
ref_type fallback ke type jika ref_type kosong
ref_id fallback ke related_id
```

Jangan membuat payload baru yang tidak kompatibel dengan admin_web/cloud.

## Acceptance criteria

- FCM dari test push tetap muncul.
- FCM dari event jadwal/approval/reminder dengan payload standar bisa dibaca.
- Foreground FCM tetap tampil sebagai local notification.
- Background/killed FCM dengan notification payload tetap muncul di status bar Android.
- `flutter analyze` pass.

---

# PATCH-02 - Dedupe FCM vs Local Reminder

## Masalah

Reminder absen nanti akan datang dari cloud/FCM sebagai jalur utama, tetapi app juga masih punya local reminder fallback. Jangan sampai user menerima dua notifikasi yang sama.

## Target file

```text
lib/services/push_notification_service.dart
lib/services/attendance_reminder_service.dart
lib/services/local_notification_service.dart
```

## Instruksi

1. Jika FCM diterima dengan `notification_id` seperti:

```text
attendance_reminder_YYYY-MM-DD_check_in_pre
attendance_reminder_YYYY-MM-DD_check_in_now
attendance_reminder_YYYY-MM-DD_check_out_pre
attendance_reminder_YYYY-MM-DD_check_out_now
```

maka app harus membatalkan scheduled local notification dengan ID yang sesuai.

2. Jangan membatalkan semua notifikasi lokal secara brutal.
3. Batalkan hanya reminder yang punya `notification_id` sama atau bisa dipetakan.
4. Jika FCM foreground ditampilkan dengan local notification, jangan munculkan local fallback kedua.
5. Jika app hanya menerima inbox/bell tanpa FCM, local fallback masih boleh bekerja.

## Acceptance criteria

- FCM reminder dari cloud tidak dobel dengan local fallback.
- Local reminder tetap berfungsi jika FCM tidak datang.
- Tidak ada pembatalan notifikasi yang tidak terkait.
- `flutter analyze` pass.

---

# PATCH-03 - Routing Tap Notifikasi Harus Konsisten

## Target file

```text
lib/services/notification_router.dart
```

## Mapping final

Pastikan payload berikut diarahkan benar:

```text
ref_type: attendance_reminder -> Home
ref_type: schedule / jadwal -> Detail Jadwal atau Home + detail jadwal
ref_type: leave / izin / cuti / sakit / approval -> Status Pengajuan/detail pengajuan
ref_type: correction / koreksi -> Status Pengajuan/detail koreksi
ref_type: qr -> Status Pengajuan/detail QR jika tersedia
ref_type: attendance / presensi -> Riwayat/detail presensi
ref_type: announcement / pengumuman -> Pengumuman
```

Jika `ref_id` kosong, fallback harus tetap aman dan tidak crash.

## Acceptance criteria

- Tap reminder membuka Home.
- Tap jadwal membuka detail jadwal.
- Tap approval membuka Status Pengajuan.
- Tap koreksi membuka Status Pengajuan filter koreksi.
- Tap presensi membuka Riwayat.
- Tap pengumuman membuka Pengumuman.
- `flutter analyze` pass.

---

# PATCH-04 - Local Notification Tetap Fallback, Bukan Jalur Utama

## Target file

```text
lib/services/attendance_reminder_service.dart
lib/features/home/home_page.dart
```

## Instruksi

1. Jangan hapus local reminder sepenuhnya.
2. Jadikan local reminder sebagai fallback saat app sudah pernah membuka Home dan jadwal hari ini tersedia.
3. Jangan menganggap local reminder sebagai sumber utama status bar.
4. Jangan menambahkan logic FCM sender di Flutter client.
5. Jika Home mendeteksi jadwal berubah dari polling, boleh tampilkan local notification sebagai fallback ringan, tetapi jalur utama tetap admin_web/cloud FCM.
6. Hindari duplikasi antara local schedule change notification dan FCM schedule notification dengan `notification_id` konsisten.

## Acceptance criteria

- App tetap menjadwalkan reminder lokal sebagai fallback.
- App tidak mencoba mengirim FCM sendiri.
- Status bar utama untuk event bisnis dipersiapkan dari FCM cloud.
- `flutter analyze` pass.

---

# PATCH-05 - Token FCM Tetap Tersimpan dan Bisa Dipakai Admin_web/Cloud

## Target file

```text
lib/services/push_notification_service.dart
```

## Instruksi

Pastikan token FCM tetap disimpan ke lokasi yang sudah digunakan:

```text
Firestore:
companies/{companyId}/fcm_tokens/{uid}/{tokenId}

RTDB mirror:
companies/{companyId}/users/{uid}/fcm_tokens/{tokenId}
```

atau path existing di project. Jangan mengganti path token tanpa alasan kuat.

Pastikan field minimal token:

```text
token
token_id
uid
company_id
platform
permission_status
active
updated_at
last_seen_at
app_source
```

## Acceptance criteria

- Test push tetap normal.
- Token aktif bisa dibaca oleh admin_web/cloud.
- Logout/deactivate token tetap aman.
- `flutter analyze` pass.

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

## FCM Receiver Check
- Payload normalization:
- Foreground handling:
- Background/killed handling:
- Token path:

## Local Fallback Check
- Reminder local fallback:
- Dedupe FCM vs local:
- Schedule change fallback:

## Routing Check
- Schedule notification route:
- Approval notification route:
- Attendance reminder route:

## Manual Build
- Tidak dijalankan oleh Codex. Build dilakukan manual oleh user.

## Notes
- Apakah kamera/history/card absen/maps tidak disentuh:
- Risiko tersisa:
```

Jangan menulis hasil build karena build tidak diminta.

---

# Urutan pengerjaan wajib

```text
1. Audit receiver FCM payload.
2. Pastikan token FCM tetap di path existing.
3. Pastikan dedupe FCM vs local reminder.
4. Pastikan routing tap notifikasi konsisten.
5. Pastikan local notification hanya fallback.
6. flutter analyze.
7. Tulis laporan akhir.
```
