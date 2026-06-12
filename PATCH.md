# PATCH.md - MYPRESENCE Notification & Attendance Reminder Polish

Dokumen ini adalah instruksi kerja untuk Codex pada repo `argajienbi/mypresence`.

Patch sebelumnya untuk single attendance card, refresh foto profil, back behavior, maps card, approval routing, dan local attendance reminder sudah dianggap selesai. Jangan sentuh lagi kecuali ada error compile langsung.

Fokus patch ini hanya:

```text
1. Pastikan semua notifikasi personal penting tampil di icon bell dan status bar Android.
2. Jadikan FCM/cloud push sebagai jalur utama status bar untuk notifikasi perubahan user.
3. Local notification tetap dipakai sebagai fallback reminder lokal, bukan satu-satunya jalur.
4. Pastikan perubahan jadwal user mengirim notifikasi status bar.
5. Pastikan reminder waktu absen sesuai jadwal bisa muncul di status bar.
```

Catatan penting dari test user:

```text
- Test push FCM berjalan normal.
- Notifikasi masuk ke menu bell.
- Tetapi reminder/jadwal berubah belum muncul di status bar.
```

Artinya sisi client sudah bisa menerima push, tetapi event bisnis tertentu kemungkinan baru menulis inbox/bell tanpa mengirim FCM. Jangan menyalahkan Android dulu. Untuk sekali ini, mungkin si robot hijau tidak sepenuhnya berdosa.

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

# PATCH-01 - FCM/Cloud sebagai Jalur Utama Status Bar

## Masalah

Saat ini data notifikasi bisa masuk ke menu bell karena record masuk ke inbox/database, tetapi belum tentu muncul di status bar Android. Untuk sistem absensi, ini kurang aman.

Semua notifikasi personal penting untuk user harus punya dua jalur:

```text
1. Bell/inbox app = record notifikasi di database.
2. Status bar Android = push notification via FCM/cloud.
```

Local notification boleh tetap ada sebagai fallback, tetapi jangan dijadikan satu-satunya jalur untuk event penting seperti jadwal berubah dan reminder absen.

## File target kemungkinan di mypresence

```text
lib/services/push_notification_service.dart
lib/services/local_notification_service.dart
lib/services/app_notification_service.dart
lib/services/attendance_reminder_service.dart
lib/services/notification_router.dart
lib/features/notifications/notifications_page.dart
lib/features/notifications/notification_detail_page.dart
```

## Target di admin_web/cloud/backend

Jika repo `admin_web` atau cloud function yang mengelola perubahan data user/jadwal, buat mekanisme server-side untuk:

```text
- menulis inbox notification
- mengambil FCM token aktif user
- mengirim FCM ke token user
```

Jangan hanya menulis ke RTDB/Firestore inbox.

## Acceptance criteria

- Setiap notifikasi personal penting masuk ke icon bell.
- Setiap notifikasi personal penting juga dikirim ke status bar via FCM.
- Jika app foreground, app tetap bisa menampilkan local notification dari payload FCM.
- Jika app background/killed, Android menampilkan status bar dari FCM.
- Local reminder tetap ada sebagai fallback, bukan jalur utama.
- `flutter analyze` pass.

---

# PATCH-02 - Semua Perubahan untuk User Harus Muncul di Status Bar

## Masalah

User mengubah jadwal user, tetapi tidak ada notifikasi status bar. Padahal perubahan jadwal adalah informasi penting.

Semua perubahan penting yang menyangkut user harus muncul di status bar, bukan hanya di menu bell.

## Event wajib status bar

Minimal event berikut wajib membuat inbox + FCM:

```text
1. Jadwal user dibuat/diubah/dihapus.
2. Shift user berubah.
3. Jam masuk/jam pulang berubah.
4. Hari kerja/libur berubah.
5. Cuti/izin/sakit/lembur disetujui.
6. Cuti/izin/sakit/lembur ditolak.
7. Koreksi presensi disetujui/ditolak.
8. QR titip absen statusnya berubah.
9. Reminder absen masuk sesuai jadwal.
10. Reminder absen pulang sesuai jadwal.
11. Warning/admin validation terkait presensi jika ada.
12. Status akun user berubah jika mempengaruhi akses.
```

## Format payload FCM yang disarankan

Gunakan format konsisten:

```json
{
  "notification_id": "unique_id",
  "company_id": "company_id",
  "uid": "target_uid",
  "title": "Jadwal Kerja Diperbarui",
  "body": "Jadwal Anda hari ini berubah menjadi 08:00 - 17:00.",
  "type": "schedule_update",
  "ref_type": "schedule",
  "ref_id": "schedule_or_assignment_id",
  "related_id": "schedule_or_assignment_id",
  "created_at": 1710000000000,
  "sender_uid": "system",
  "sender_name": "Sistem",
  "sender_role": "system"
}
```

Untuk approval:

```json
{
  "notification_id": "unique_id",
  "title": "Cuti Disetujui",
  "body": "Pengajuan cuti Anda telah disetujui.",
  "type": "approval",
  "ref_type": "leave",
  "ref_id": "request_id"
}
```

Untuk reminder:

```json
{
  "notification_id": "attendance_reminder_2026-06-11_check_in_now",
  "title": "Waktunya absen masuk",
  "body": "Silakan absen masuk sesuai jadwal hari ini.",
  "type": "reminder",
  "ref_type": "attendance_reminder",
  "ref_id": "attendance_reminder_2026-06-11_check_in_now",
  "reminder_action": "check_in",
  "reminder_stage": "now"
}
```

## Acceptance criteria

- Setelah admin mengubah jadwal user, user mendapat notifikasi status bar.
- Notifikasi jadwal berubah juga masuk bell.
- Tap notifikasi jadwal membuka Home/detail jadwal.
- Approval pengajuan tetap masuk bell dan status bar.
- Reminder absen tetap masuk bell dan status bar.

---

# PATCH-03 - Pastikan Token FCM Aktif Dipakai oleh Sender

## Kondisi mypresence

App sudah punya service untuk register token FCM dan mirror ke Firestore/RTDB. Jangan membuat sistem token baru kalau yang lama sudah berjalan.

## Instruksi

1. Pastikan saat user login, token FCM tersimpan.
2. Pastikan backend/admin_web membaca token aktif dari lokasi yang sama dengan yang ditulis app.
3. Token yang `active == false` jangan dikirim.
4. Jika ada banyak device, kirim ke semua token aktif user.
5. Jika FCM gagal karena token invalid/unregistered, tandai token inactive.

## Acceptance criteria

- Test push manual tetap berjalan.
- Notifikasi event bisnis memakai token FCM yang sama.
- Jika user punya lebih dari satu device aktif, semua device aktif bisa menerima push.
- Ada debug/status token yang bisa dicek admin.

---

# PATCH-04 - Bedakan Inbox Notification dan Push Delivery

## Masalah

Jangan anggap record bell/inbox sama dengan status bar.

Yang benar:

```text
write notification inbox != send push notification
```

Harus ada helper/fungsi terpusat di cloud/admin backend:

```text
createUserNotificationAndPush(...)
```

Helper ini harus melakukan dua hal:

```text
1. Tulis notifikasi ke Firestore/RTDB inbox.
2. Kirim FCM ke token aktif user.
```

## Instruksi implementasi backend/admin_web

Buat service notifikasi terpusat, misalnya:

```text
NotificationDeliveryService
```

Fungsi minimal:

```text
sendToUser({
  companyId,
  uid,
  title,
  body,
  type,
  refType,
  refId,
  relatedId,
  data,
})
```

Isi pekerjaan:

```text
- generate notification_id
- tulis inbox notification
- ambil FCM tokens aktif
- kirim FCM notification + data payload
- simpan delivery log
```

## Acceptance criteria

- Tidak ada event penting yang hanya menulis bell tanpa push.
- Tidak ada event penting yang hanya push tanpa menulis bell.
- Delivery log bisa membantu debug jika status bar tidak muncul.

---

# PATCH-05 - Reminder Absen: FCM Utama, Local Fallback

## Masalah

Reminder lokal bisa gagal tampil karena permission, exact alarm, battery optimization, app belum membuka Home, atau Android menunda inexact alarm. Ini wajar, karena Android tampaknya menganggap semua aplikasi adalah gangguan sampai dibuktikan sebaliknya.

## Arsitektur final

Gunakan hybrid:

```text
FCM/cloud reminder = jalur utama.
Local notification = fallback saat app aktif atau Home pernah dibuka.
Bell/inbox = riwayat notifikasi.
```

## Instruksi

1. Server/cloud mengecek jadwal user.
2. Saat sudah waktunya reminder:

```text
- 10 menit sebelum jam masuk
- tepat jam masuk
- 10 menit sebelum jam pulang
- tepat jam pulang
```

3. Server menulis inbox dan mengirim FCM.
4. App tetap boleh menjadwalkan local notification sebagai fallback.
5. Cegah duplikasi UI jika FCM dan local fallback muncul bersamaan:

```text
- gunakan notification_id/ref_id yang sama
- dedupe berdasarkan notification_id/ref_type/ref_id
```

## Jangan kirim reminder jika

```text
- user sudah absen masuk untuk check_in
- user sudah absen pulang untuk check_out
- user punya cuti/izin/sakit disetujui hari ini
- hari libur
- bukan workday
- jadwal tidak tersedia
```

## Acceptance criteria

- Reminder tetap muncul di status bar walaupun user tidak membuka Home hari itu.
- Reminder tetap masuk bell.
- Local fallback tidak membuat duplikasi parah.
- Tap reminder membuka Home/Presensi.

---

# PATCH-06 - Routing Tap Notifikasi

## Instruksi

Pastikan payload berikut diarahkan benar:

```text
ref_type: attendance_reminder -> Home
ref_type: schedule / jadwal -> Home + detail jadwal jika tersedia
ref_type: leave / izin / cuti / sakit / approval -> Status Pengajuan/detail pengajuan
ref_type: correction / koreksi -> Status Pengajuan/detail koreksi
ref_type: qr -> Status Pengajuan/detail QR jika tersedia
ref_type: attendance / presensi -> Riwayat/detail presensi
ref_type: announcement / pengumuman -> Pengumuman
```

## Acceptance criteria

- Tap notifikasi jadwal membuka halaman yang relevan.
- Tap reminder absen membuka Home.
- Tap approval membuka Status Pengajuan.
- Fallback aman jika ref_id tidak tersedia.

---

# PATCH-07 - Manual Test Wajib

Codex wajib menulis catatan manual test di laporan akhir:

```text
Manual test status bar:
1. Pastikan test push FCM masih normal.
2. Login sebagai user dan pastikan token aktif tersimpan.
3. Dari admin/admin_web, ubah jadwal user.
4. User harus menerima status bar notification.
5. Buka icon bell, notifikasi jadwal berubah harus muncul.
6. Tap status bar, harus membuka Home/detail jadwal.
7. Buat jadwal absen 5-15 menit dari waktu sekarang.
8. Tunggu reminder pre/now.
9. Reminder harus muncul di status bar dan bell.
10. Setelah user absen, reminder terkait tidak boleh muncul lagi.
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

## Notification Delivery Check
- Bell/inbox write:
- FCM push send:
- Local fallback:
- Token source:
- Delivery log/debug:

## Routing Check
- Schedule notification route:
- Approval notification route:
- Attendance reminder route:

## Manual Build
- Tidak dijalankan oleh Codex. Build dilakukan manual oleh user.

## Manual Test Notes
- Cara test status bar jadwal berubah:
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
1. Audit apakah event jadwal berubah hanya menulis bell atau juga mengirim FCM.
2. Tambahkan/siapkan FCM delivery untuk semua event personal penting.
3. Pastikan token FCM aktif dipakai sender.
4. Pastikan bell inbox dan push delivery selalu dibuat bersama.
5. Jadikan FCM jalur utama reminder absen, local notification fallback.
6. Pastikan routing tap notifikasi benar.
7. flutter analyze.
8. Tulis laporan akhir lengkap dengan manual test.
```
