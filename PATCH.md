# PATCH.md - MYPRESENCE Reminder Absen Statusbar

Instruksi kerja untuk Codex pada repo `argajienbi/mypresence`.

Fokus patch: sambungkan reminder absen statusbar Flutter dengan konfigurasi dari admin web. Jangan rewrite project. Jangan ubah Firebase config, flow presensi, kamera, radius, QR, login, history, atau inbox notifikasi.

## Tujuan

- Reminder absen tetap muncul di statusbar.
- Waktu reminder tidak lagi hard-code 10 menit.
- App membaca konfigurasi dari RTDB.
- App tetap aman jika konfigurasi kosong.
- Field lama tetap kompatibel.

## File prioritas

- `lib/services/attendance_reminder_service.dart`
- `lib/services/push_notification_service.dart`
- `lib/features/home/home_page.dart`
- `lib/services/local_notification_service.dart`
- `lib/services/notification_service.dart`
- `lib/services/schedule_service.dart`
- `lib/core/utils.dart`

## Path konfigurasi RTDB

```text
companies/{companyId}/notification_settings/main
```

## Field utama yang harus dibaca

```text
attendance_reminder_enabled
reminder_check_in_pre_enabled
reminder_check_in_now_enabled
reminder_check_in_late_enabled
reminder_check_out_pre_enabled
reminder_check_out_now_enabled
reminder_check_out_late_enabled
reminder_check_in_pre_minutes
reminder_check_in_now_window_minutes
reminder_check_in_late_minutes
reminder_check_out_pre_minutes
reminder_check_out_now_window_minutes
reminder_check_out_late_minutes
reminder_scheduler_catchup_minutes
```

## Field legacy fallback

```text
pre_check_in_enabled
pre_check_in_minutes
missed_check_in_enabled
missed_check_in_minutes
pre_check_out_enabled
pre_check_out_minutes
missed_check_out_enabled
missed_check_out_minutes
```

Mapping legacy:

```text
pre_check_in_enabled -> reminder_check_in_pre_enabled
pre_check_in_minutes -> reminder_check_in_pre_minutes
missed_check_in_enabled -> reminder_check_in_late_enabled
missed_check_in_minutes -> reminder_check_in_late_minutes
pre_check_out_enabled -> reminder_check_out_pre_enabled
pre_check_out_minutes -> reminder_check_out_pre_minutes
missed_check_out_enabled -> reminder_check_out_late_enabled
missed_check_out_minutes -> reminder_check_out_late_minutes
```

## Default jika setting kosong

```text
attendance_reminder_enabled = true
checkInPreEnabled = true
checkInNowEnabled = true
checkInLateEnabled = false
checkOutPreEnabled = true
checkOutNowEnabled = true
checkOutLateEnabled = false
checkInPreMinutes = 10
checkInNowWindowMinutes = 6
checkInLateMinutes = 10
checkOutPreMinutes = 10
checkOutNowWindowMinutes = 6
checkOutLateMinutes = 10
schedulerCatchUpMinutes = 6
```

## Implementasi di `attendance_reminder_service.dart`

1. Tambahkan model kecil, boleh private, misalnya `_AttendanceReminderSettings`.
2. Tambahkan loader:

```dart
static Future<_AttendanceReminderSettings> _loadSettings(AppSession session)
```

Loader membaca path:

```dart
_database.ref('companies/${session.companyId}/notification_settings/main')
```

Jika snapshot kosong atau error, return default. Jangan throw ke UI.

3. Tambahkan helper parser:

```dart
static bool _readBool(Map<String, dynamic> data, List<String> keys, bool fallback)
static int _readInt(Map<String, dynamic> data, List<String> keys, int fallback, {required int min, required int max})
```

Aturan parser:

- bool menerima `true`, `false`, `"true"`, `"false"`, `"1"`, `"0"`, `1`, `0`.
- int menerima number dan string angka.
- nilai `0` jangan dianggap kosong.
- clamp angka ke batas aman.

Batas angka:

```text
checkInPreMinutes: 0..120
checkInNowWindowMinutes: 0..30
checkInLateMinutes: 1..180
checkOutPreMinutes: 0..120
checkOutNowWindowMinutes: 0..30
checkOutLateMinutes: 1..240
schedulerCatchUpMinutes: 5..30
```

## Perubahan `scheduleToday`

Di awal `scheduleToday`, load setting:

```dart
final settings = await _loadSettings(session);
```

Jika disabled, clear semua reminder check-in dan check-out lalu return.

Jika jadwal null, off, libur, atau user punya cuti/izin approved, clear semua reminder check-in dan check-out lalu return.

Untuk check-in:

- `pre`: jika enabled, jadwalkan pada `workStart - checkInPreMinutes`.
- `now`: jika enabled, jadwalkan pada `workStart`.
- `late`: jika enabled, jadwalkan pada `workStart + checkInLateMinutes`.
- jika user sudah check-in, clear semua reminder check-in.

Untuk check-out:

- `pre`: jika enabled, jadwalkan pada `adjustedEnd - checkOutPreMinutes`.
- `now`: jika enabled, jadwalkan pada `adjustedEnd`.
- `late`: jika enabled, jadwalkan pada `adjustedEnd + checkOutLateMinutes`.
- jika user sudah check-out, clear semua reminder check-out.

## Tambahkan stage `late`

Stage reminder harus mendukung:

```text
pre
now
late
```

Update bagian ini:

- `_clearReminderGroup`
- `_scheduledNotificationId`
- `_localNotificationIdFromNotificationId`
- regex parser notification id

Regex harus menerima:

```dart
(pre|now|late)
```

Variant ID:

```text
pre = 0
now = 1
late = 2
```

## Payload notifikasi

Jangan hapus field lama berikut:

```text
id
notification_id
title
body
message
type
ref_type
ref_id
related_id
reminder_action
reminder_stage
created_at
scheduled_at
created_date
created_time
sender_uid
sender_name
sender_role
read
is_read
active
source
```

Boleh tambah:

```text
settings_source = companies_notification_settings
reminder_config_version = 1
```

## Catch-up window

Gunakan `settings.schedulerCatchUpMinutes` untuk toleransi catch-up. Tetap gunakan mekanisme `_wasLocallyDelivered` dan `_markLocallyDelivered` agar tidak spam statusbar.

## Push FCM

Jangan rusak pemanggilan:

```dart
AttendanceReminderService.cancelScheduledReminderByNotificationId(...)
```

di `PushNotificationService`. Ini dibutuhkan agar push server bisa membatalkan local scheduled notification.

## Acceptance criteria

- `flutter analyze` berhasil.
- App tetap login normal.
- Home tetap membaca jadwal.
- Reminder tetap muncul di statusbar.
- Setting admin mengubah menit reminder.
- Admin bisa enable/disable `pre`, `now`, `late` untuk check-in dan check-out.
- Nilai `0` tetap valid untuk field yang boleh 0.
- Reminder tidak muncul saat user sudah absen.
- Reminder tidak muncul saat cuti/izin approved.
- Reminder tidak muncul saat jadwal off/libur.
- Payload tetap terbaca di inbox.
- FCM push tetap bisa cancel local reminder.

## Test manual

1. Isi RTDB `companies/{companyId}/notification_settings/main`.
2. Set `attendance_reminder_enabled = true`.
3. Set `reminder_check_in_pre_enabled = true` dan `reminder_check_in_pre_minutes = 5`.
4. Set `reminder_check_out_pre_enabled = true` dan `reminder_check_out_pre_minutes = 0`.
5. Login user yang punya jadwal hari ini.
6. Buka Home.
7. Pastikan local notification mengikuti setting.
8. Lakukan check-in dan pastikan reminder check-in dibersihkan.
9. Lakukan check-out dan pastikan reminder check-out dibersihkan.

## Catatan

Admin web adalah pusat konfigurasi. Flutter wajib fallback aman jika konfigurasi kosong. Field legacy tetap dibaca agar kompatibel dengan data lama dan worker lama.
