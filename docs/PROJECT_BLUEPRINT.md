# MyPresence Project Blueprint / Handoff Notes

Dokumen ini dibuat untuk menjaga seluruh konteks project agar aman jika percakapan ChatGPT error atau perlu dipindahkan ke percakapan baru.

Project terdiri dari:

- Flutter app: `argajienbi/mypresence`
- Admin web: `argajienbi/admin_web`
- Backend Cloud Functions: `mypresensi-backend` / Firebase Functions project `inventory-410f4`

Tanggal konteks terakhir: 2026-05-27.

---

## 1. Tujuan Project

MyPresence adalah aplikasi presensi karyawan berbasis Flutter + Firebase dengan admin web untuk perusahaan.

Fitur utama:

- Presensi clock in / clock out menggunakan GPS dan selfie.
- Validasi radius kantor.
- Jadwal kerja rutin, jadwal khusus, hari libur, dan jadwal lembur.
- Pengajuan izin, sakit, cuti, lembur.
- QR / proxy attendance.
- Push notification via Firebase Cloud Messaging.
- Admin web untuk mengelola company, user, jadwal, pengajuan, laporan, notifikasi.
- Owner tools untuk kesehatan database dan reset data dummy.

---

## 2. Repository Flutter App: `argajienbi/mypresence`

### 2.1 Package / App ID

App sudah diganti dari identitas lama ke:

```text
com.mypresence
```

Masalah sebelumnya:

```text
java.lang.ClassNotFoundException: com.mypresence.MainActivity
```

Penyebab: package / MainActivity belum konsisten. Sudah diperbaiki sebelumnya.

---

## 3. Struktur Home Flutter App

Status terakhir setelah revisi:

```text
Header MY PRESENCE
RadiusCard
Tombol Clock In / Clock Out
Tile Status + Detail Jadwal
Menu Cepat
```

Perubahan penting:

- Kartu besar `HomeSchedulePreview` sempat ditampilkan langsung di Home, tetapi terlihat duplikat.
- Sudah dipindah ke bottom sheet `Detail Jadwal`.
- Home sekarang lebih ringkas.

File terkait:

```text
lib/features/home/home_page.dart
lib/features/home/widgets/home_schedule_preview.dart
```

### 3.1 HomeSchedulePreview

Widget:

```text
lib/features/home/widgets/home_schedule_preview.dart
```

Fungsi:

- Menampilkan jadwal dalam mode:
  - Harian
  - Mingguan
  - Bulanan
- Default mode: Harian.
- Tombol kiri / kanan untuk pindah tanggal, minggu, bulan.
- Horizontal scroll untuk minggu dan bulan.
- Badge status:
  - Reguler
  - Khusus
  - Lembur
  - Libur
  - Tidak ada

Sekarang widget ini dipakai di bottom sheet `Detail Jadwal`, bukan di Home utama.

---

## 4. ScheduleService Flutter

File:

```text
lib/services/schedule_service.dart
```

Perubahan besar:

- `resolveToday()` memakai `resolveForDate()`.
- Tambah `resolveForDate(AppSession session, DateTime dateTime)`.
- Tambah `resolveRange(AppSession session, DateTime start, DateTime end)`.
- Resolver sekarang mendukung jadwal lembur dari path `overtime_schedules/{companyId}`.

Prioritas resolver jadwal:

```text
1. overtime_schedules
2. schedule_specials
3. holidays
4. schedule_assignments
```

Aturan:

- Jika user masuk `target_uids` jadwal lembur dan tanggal cocok di `dates`, maka jadwal lembur menang atas hari libur nasional.
- Hari libur nasional hanya memblokir presensi jika user tidak punya jadwal lembur / jadwal khusus.

Format `overtime_schedules` yang dibaca Flutter:

```json
{
  "schedule_id": "ot_123",
  "company_id": "company_1",
  "name": "Lembur Libur Nasional Shift Pagi",
  "mode": "group",
  "target_type": "group",
  "target_uids": {
    "uidA": true,
    "uidB": true
  },
  "target_count": 2,
  "dates": {
    "2026-05-31": true,
    "2026-06-01": true
  },
  "work_start": "08:00",
  "work_end": "16:00",
  "check_in_start": "07:30",
  "check_in_end": "09:00",
  "check_out_start": "15:30",
  "check_out_end": "17:00",
  "note": "Operasional hari libur nasional",
  "status": "active",
  "active": true,
  "created_by": "admin_uid",
  "created_by_name": "Admin",
  "created_at": 1779860000000,
  "updated_at": 1779860000000
}
```

Attendance payload sekarang menyimpan:

```text
schedule_source: overtime_schedule
overtime_schedule_id: scheduleId
overtime_flag: true
is_holiday_work: true / false
```

---

## 5. Firebase Paths Flutter

File:

```text
lib/core/firebase_paths.dart
```

Path baru:

```dart
static String overtimeSchedules(String companyId) => 'overtime_schedules/$companyId';
static String overtimeSchedule(String companyId, String scheduleId) => 'overtime_schedules/$companyId/$scheduleId';
```

---

## 6. Push Notification Flutter

Status:

- Push notification sudah berhasil muncul di status bar.
- Icon notifikasi sudah tidak lagi Flutter default setelah perbaikan icon sebelumnya.
- Tap notification awalnya hanya menghilangkan notif, kemudian diarahkan berdasarkan payload `ref_type`.

Ref type yang dipakai:

```text
announcement      -> Pengumuman / detail notifikasi
leave_request     -> Riwayat / pengajuan
attendance         -> Riwayat presensi
schedule           -> Home + Detail Jadwal
```

Jangan pakai `ref_type: test` untuk uji tap notifikasi karena app tidak tahu tujuan navigasinya.

---

## 7. Menu Cepat Flutter

Menu Cepat saat ini:

```text
Izin
Sakit
Cuti
Lembur
QR
Notifikasi
```

Catatan:

- `QR Teman` sudah direncanakan/diganti menjadi `QR`.
- Izin/sakit/cuti/lembur harus mendukung lampiran jika diperlukan.
- Sakit idealnya wajib melampirkan bukti foto/dokumen.

---

## 8. Detail Jadwal Flutter

Setelah revisi terakhir:

- Tombol `Detail Jadwal` membuka bottom sheet.
- Bottom sheet berisi `HomeSchedulePreview` dengan mode Harian/Mingguan/Bulanan.
- Bottom sheet dibuat scrollable agar aman di layar kecil.

Catatan UI:

- Home tidak lagi menampilkan kartu jadwal besar agar tidak duplikat.
- Jika ingin halaman penuh nanti, `HomeSchedulePreview` bisa dipindah ke page terpisah `SchedulePage`.

---

## 9. Admin Web: `argajienbi/admin_web`

Admin web digunakan untuk:

- Pengelolaan perusahaan dan karyawan.
- Jadwal kerja.
- Jadwal lembur.
- Approval izin/sakit/cuti/lembur.
- Pengumuman dan notifikasi.
- Reports / rekap.
- Owner database health.

Aturan kerja penting:

```text
Untuk admin_web, ChatGPT sebaiknya membuat patch.md jika diminta patch.
AI Studio yang menjalankan patch.
Setelah AI Studio selesai, ChatGPT mengecek repo.
```

Namun beberapa patch sebelumnya sudah dicek dan sebagian sudah diterapkan oleh AI Studio.

---

## 10. Admin Web - Test Push

Fitur Test Push harus ada agar admin bisa test notifikasi tanpa input manual Firebase.

Jenis Test Push:

```text
Test Pengumuman       -> ref_type: announcement
Test Pengajuan        -> ref_type: leave_request
Test Riwayat Presensi -> ref_type: attendance
Test Jadwal           -> ref_type: schedule
```

Payload minimal queue:

```text
uid
company_id
title
body
message
type
ref_type
ref_id
related_id
status: pending
created_at
sent_at: null
failed_at: null
failed_count: 0
success_count: 0
token_count: 0
```

Path Firestore queue:

```text
companies/{companyId}/notification_queue/{queueId}
```

Cloud Function yang memproses queue:

```text
onNotificationQueueCreated asia-southeast2
```

Status terakhir:

- Push berhasil muncul di device.
- Test push dengan `ref_type: schedule` berhasil memunculkan notifikasi `Jadwal Lembur Ditambahkan`.

---

## 11. Admin Web - Notification Logs

Log notifikasi harus menampilkan:

```text
Queue ID
UID
Ref Type
Ref ID
Token Count
Success Count
Failed Count
Status
Error
```

Jika queue gagal dibuat, error tidak boleh disembunyikan.

---

## 12. Admin Web - Approval Izin/Sakit/Cuti/Lembur

File utama kemungkinan:

```text
src/pages/Approvals.tsx
```

Field Flutter baru/lama yang harus kompatibel:

```text
user_name fallback nama_lengkap
type fallback leave_type
date_start fallback tanggal_mulai / tanggal
date_end fallback tanggal_selesai / date_start / tanggal
reason fallback alasan
attachment_url / attachment_path
attachment_name
```

Untuk lembur tampilkan:

```text
overtime_date
overtime_start_time
overtime_end_time
overtime_duration_minute
```

Notifikasi approval:

```text
Izin Disetujui / Izin Ditolak
Sakit Disetujui / Sakit Ditolak
Cuti Disetujui / Cuti Ditolak
Lembur Disetujui / Lembur Ditolak
```

Payload approval notification:

```text
ref_type: leave_request
ref_id: request_id
type: success / danger
```

---

## 13. Admin Web - Jadwal Lembur

Konsep final:

```text
Jadwal -> Jadwal Lembur
```

Flow:

```text
1. Admin membuat grup lembur.
2. Admin mengisi nama grup lembur.
3. Admin memilih karyawan yang masuk grup.
4. Admin memilih satu atau lebih tanggal lembur dari kalender.
5. Admin mengatur jam kerja lembur.
6. Admin mengatur jendela clock in dan clock out.
7. Data otomatis menjadi sumber jadwal karyawan pada tanggal yang dipilih.
```

Untuk perorangan:

```text
Buat grup lembur berisi 1 karyawan saja.
```

Tidak perlu lagi:

```text
tanggal mulai
tanggal selesai
pilihan hari mingguan
mode perorangan terpisah
```

Field final:

```ts
{
  schedule_id: string,
  company_id: string,
  name: string,
  mode: "group",
  target_type: "group",
  target_uids: Record<string, true>,
  target_count: number,
  dates: Record<string, true>,
  work_start: string,
  work_end: string,
  check_in_start: string,
  check_in_end: string,
  check_out_start: string,
  check_out_end: string,
  note: string,
  status: "active" | "inactive",
  active: boolean,
  created_by: string,
  created_by_name: string,
  created_at: number,
  updated_at: number
}
```

Path:

```text
overtime_schedules/{companyId}/{scheduleId}
```

Saat jadwal lembur dibuat/diubah:

- Kirim push ke semua target user.
- Gunakan `ref_type: schedule`.
- Title contoh: `Jadwal Lembur Ditambahkan` / `Jadwal Lembur Diperbarui`.

---

## 14. Admin Web - Conflict Alert Jadwal Lembur

Catatan patch terakhir:

Harus ada hard block jika jadwal lembur bertabrakan.

Cek bentrok:

```text
selectedDates vs overtimeSchedules existing
selectedUids vs target_uids existing
work_start/work_end overlap
edit jadwal skip jadwal dengan id sendiri
```

Contoh konflik:

```text
Jadwal A:
Budi, 28 Mei, 06:00-12:00

Jadwal B:
Budi, 28 Mei, 10:00-15:00

Harus ditolak.
```

Aturan overlap:

- Jam yang overlap harus ditolak.
- Jam yang tidak overlap boleh disimpan.
- Jadwal inactive tidak dihitung sebagai konflik.

---

## 15. Admin Web - Diagnostic Jadwal

Diagnostic harus cek prioritas:

```text
1. overtime_schedules
2. schedule_specials
3. holidays
4. schedule_assignments
```

Jika user punya jadwal lembur pada hari libur:

```text
Result: Jadwal Lembur Aktif
canAttend: true
reason: Libur nasional tidak memblokir presensi untuk user ini.
```

Jika user tidak masuk jadwal lembur:

```text
Result: Hari Libur
canAttend: false
```

---

## 16. Admin Web - Reports / Rekap

Reports harus menghitung:

```text
Approved izin/sakit/cuti
Approved lembur user request
Lembur dari overtime_schedule
```

Sumber lembur:

```text
1. User Request
   leave_requests type/leave_type == lembur status approved/validated

2. Jadwal Lembur
   attendance schedule_source == overtime_schedule OR overtime_flag == true
```

Ringkasan laporan yang diinginkan:

```text
Total Lembur
Total Jam Lembur
Lembur User Request
Lembur Terjadwal
```

---

## 17. Admin Web - Owner Database Health

Menu khusus role `owner`:

```text
Owner Tools -> Kesehatan Database
```

Atau route:

```text
/database-health
```

Fitur:

```text
Ringkasan database:
- jumlah companies
- jumlah users
- jumlah company_users
- attendance
- leave_requests
- qr_attendance_requests
- attendance_corrections
- announcements
- audit_logs
- schedule_assignments
- schedule_specials
- overtime_schedules
- holidays
- schedule_change_logs
- timetables
- shifts
- storage_index
- report_cache
```

Estimasi:

```text
total children
estimasi ukuran JSON
estimasi node
node terbesar
```

Storage:

- Storage usage asli sulit dihitung akurat dari client web.
- Tahap awal cukup baca `storage_index/{companyId}`.
- Untuk akurat perlu Cloud Function / Admin SDK scan bucket.

Reset dummy data:

- Khusus owner.
- Per company.
- Konfirmasi manual harus mengetik:

```text
RESET DATABASE
```

Data yang boleh direset default:

```text
attendance
leave_requests
qr_attendance_requests
attendance_corrections
announcements
audit_logs optional
schedule_change_logs optional
overtime_schedules
schedule_specials
schedule_assignments optional
holidays optional
report_cache
storage_index optional
notifications per user
notification_queue Firestore optional
```

Data yang tidak boleh dihapus default:

```text
users
companies
company_users
offices
departments
sub_departments
employee_groups
timetables
shifts
app_config
```

Audit log wajib:

```text
action: OWNER_DATABASE_RESET
company_id
company_name
paths_deleted
admin_uid
admin_name
created_at
```

---

## 18. Backend / Cloud Functions

Project backend ada di Termux/local sebagai `mypresensi-backend`.

Deploy berhasil:

```bash
firebase deploy --only functions
```

Function:

```text
onNotificationQueueCreated(asia-southeast2)
```

Runtime warning:

```text
Node.js 20 deprecated on 2026-04-30 and decommissioned on 2026-10-30.
```

Catatan:

- Nanti upgrade runtime functions sebelum deadline.
- `firebase-functions` package sempat warning outdated.

Masalah sebelumnya:

```text
PERMISSION_DENIED Missing or insufficient permissions
```

Sudah diperbaiki melalui rules/permission backend sehingga test push berhasil.

---

## 19. Firebase / Database Paths Penting

Realtime Database paths:

```text
users/{uid}
companies/{companyId}
company_users/{companyId}/{uid}
offices/{companyId}
departments/{companyId}
sub_departments/{companyId}
employee_groups/{companyId}
timetables/{companyId}
shifts/{companyId}
schedule_assignments/{companyId}
schedule_specials/{companyId}
overtime_schedules/{companyId}
holidays/{companyId}
schedule_change_logs/{companyId}
attendance/{companyId}/{uid}/{date}/{actionType}
leave_requests/{companyId}
qr_attendance_requests/{companyId}
attendance_corrections/{companyId}
announcements/{companyId}
audit_logs/{companyId}
notifications/{uid}
report_cache/{companyId}
storage_index/{companyId}
```

Firestore path:

```text
companies/{companyId}/notification_queue/{queueId}
companies/{companyId}/notification_logs/{logId}
```

---

## 20. Commands Penting

Flutter app:

```bash
git pull origin main
flutter analyze
flutter build apk --release
flutter build apk --release --target-platform android-arm64
```

Jika `flutter` tidak dikenali di Windows:

```text
Pastikan Flutter SDK ada di PATH.
Atau jalankan dari terminal yang sudah mengenali Flutter.
```

Backend deploy:

```bash
cd ~/mypresensi-backend
firebase deploy --only functions
```

Admin web:

```bash
npm install
npm run build
```

---

## 21. Catatan UI / UX

### Home Flutter

- Jangan tampilkan jadwal besar langsung di Home karena terasa duplikat.
- Jadwal lengkap cukup di `Detail Jadwal`.
- Home utama fokus:
  - radius
  - tombol absen
  - status
  - detail jadwal
  - menu cepat

### Jadwal Flutter

- Detail Jadwal default Harian.
- Mingguan dan Bulanan tersedia di bottom sheet.
- Gunakan badge warna:
  - Reguler: hijau
  - Khusus: biru
  - Lembur: ungu/teal
  - Libur: oranye/merah
  - Tidak ada: abu

### Admin Web Jadwal Lembur

- Buat flow sederhana.
- Admin cukup input:
  - nama grup
  - pilih karyawan
  - pilih tanggal satu atau banyak
  - set jam kerja/clock in/clock out
- Jangan pakai date_start/date_end/pilihan hari di UI.

---

## 22. Catatan Testing Wajib

Flutter:

```text
flutter analyze harus bersih.
Build APK release harus berhasil.
Test device asli:
- login
- radius
- clock in/out
- jadwal reguler
- jadwal khusus
- jadwal lembur hari libur
- push notif
- tap notif schedule
- detail jadwal harian/mingguan/bulanan
```

Admin web:

```text
npm run build harus berhasil.
Test:
- Test Push announcement
- Test Push leave_request
- Test Push attendance
- Test Push schedule
- Jadwal Lembur multi tanggal
- Conflict jadwal lembur
- Diagnostic jadwal lembur vs holiday
- Owner Database Health
- Reset dummy data
```

Backend:

```text
Deploy functions berhasil.
Buat notification_queue pending.
Pastikan status berubah sent.
Pastikan success_count naik.
Pastikan push muncul di device.
```

---

## 23. Sisa / TODO Terakhir

### Flutter

```text
[ ] Tunggu hasil flutter analyze setelah patch terakhir.
[ ] Jika analyze error, perbaiki tanpa mengubah flow besar.
[ ] Test Detail Jadwal bottom sheet di device kecil.
[ ] Test tap push ref_type schedule membuka Detail Jadwal.
[ ] Test attendance dari overtime_schedule menyimpan overtime_flag.
```

### Admin Web

```text
[ ] Pastikan patch Database Health benar-benar diterapkan AI Studio.
[ ] Pastikan menu Database Health hanya muncul untuk owner.
[ ] Pastikan conflict alert Jadwal Lembur sudah hard block.
[ ] Pastikan notification_queue Firestore bisa direset atau minimal dicatat TODO aman.
[ ] Pastikan npm run build bersih.
```

### Backend

```text
[ ] Upgrade Node.js runtime sebelum 2026-04-30.
[ ] Upgrade firebase-functions package dengan hati-hati.
[ ] Tambahkan backend scheduled reminders jika nanti local reminder tidak cukup.
```

---

## 24. Cara Melanjutkan di Percakapan Baru

Di percakapan baru, kirim instruksi:

```text
Lanjutkan project MyPresence. Baca docs/PROJECT_BLUEPRINT.md di repo argajienbi/mypresence dan argajienbi/admin_web. Itu adalah sumber konteks utama. Fokus saat ini: cek hasil flutter analyze, cek admin_web Database Health, dan pastikan Jadwal Lembur tidak bentrok serta override holiday.
```

Prioritas pertama di percakapan baru:

```text
1. Cek flutter analyze dari repo mypresence.
2. Jika ada error, perbaiki.
3. Cek admin_web apakah patch Database Health sudah masuk.
4. Cek npm run build admin_web.
5. Test Jadwal Lembur dari admin_web sampai tampil di Flutter Detail Jadwal.
```

---

## 25. Commit Penting Terakhir Flutter

Beberapa commit penting yang terjadi selama percakapan:

```text
14c9556107a1c5ba4647c2dd2a709241764df9c0 - Add overtime schedule database paths
f24c23ae293fef173ddab8000727d494570afdec - Resolve overtime schedules before holidays
bea6347b99dc863c7d2e85baa3e2102b49268ef9 - Add home schedule preview widget
d166940860bc878e7d809687124fdad546bc2287 - Show schedule preview on home
e6f6f5c5632165841bdd4f279475fb76049842b6 - Move schedule preview into detail sheet
```

---

## 26. Prinsip Teknis untuk Perubahan Berikutnya

```text
- Hindari rewrite total.
- Jaga flutter analyze tetap bersih.
- Untuk kode Flutter, gunakan kode full utuh, bukan tambal sulam.
- Untuk admin_web, buat patch.md jika diminta dan biarkan AI Studio menjalankan, kecuali user meminta langsung cek repo.
- Jangan menghapus path lama yang sudah dipakai Flutter.
- Semua fitur jadwal harus tetap kompatibel dengan data lama jika mungkin.
- Jadwal Lembur harus selalu menang atas holiday untuk user target.
- Reset database harus aman dan tidak menghapus master data default.
```
