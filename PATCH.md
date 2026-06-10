# PATCH.md - MYPRESENCE Flutter App Polish Batch

Dokumen ini adalah instruksi kerja untuk Codex pada repo `argajienbi/mypresence`.

Peran Codex: implementer teknis Flutter app.
Peran ChatGPT: orkestrator dan reviewer.

Tujuan patch ini adalah menyempurnakan fitur yang sudah dibuat pada batch sebelumnya, bukan membongkar ulang aplikasi. Jangan refactor besar, jangan rename package, dan jangan build.

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
existing RTDB path yang sudah berjalan
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

Build akan dilakukan manual oleh user.

---

## Prinsip kerja wajib

1. Jangan refactor besar.
2. Jangan menghapus flow login, splash, home, attendance selfie, QR attendance, leave, schedule, history, profile, notification, atau camera yang sudah berjalan.
3. Jangan mengubah data final attendance langsung dari mobile selain flow selfie/QR request yang sudah ada.
4. Semua koreksi presensi tetap berupa request `pending` untuk admin.
5. Semua fitur baru harus aman untuk data lama yang field-nya belum lengkap.
6. Jangan menambah dependency baru kecuali benar-benar diperlukan.
7. Jika menambah UI baru, gunakan style/theme yang sudah ada.
8. Semua error harus memakai `friendlyError`, `AppToast`, atau UI pesan ramah yang sudah dipakai project.
9. Validasi akhir cukup `flutter analyze`.

---

# Target patch kali ini

Kerjakan poin berikut dalam satu batch:

```text
1. Koreksi Presensi dari ALPA dan duplikat overlap
2. Detail Status Pengajuan
3. Preview foto/lampiran
4. Lihat lokasi dari detail presensi
5. Warning lokasi/foto lebih jelas
6. Badge pending pengajuan
7. Filter jenis pengajuan
8. Fix Detail Presensi agar lokasi dibaca dari nested masuk/pulang
```

---

# PATCH-POLISH-01 - Koreksi Presensi dari ALPA dan duplikat overlap

## Masalah

Saat ini tombol `Ajukan Koreksi` hanya muncul jika item History punya attendance record. Padahal user paling sering butuh koreksi untuk kasus:

```text
ALPA
lupa absen masuk
lupa absen pulang
hari kerja tanpa data presensi
```

Selain itu, validasi duplikat koreksi harus lebih kuat untuk tipe yang saling tumpang tindih.

## File target

```text
lib/features/history/attendance_detail_sheet.dart
lib/features/corrections/attendance_correction_form_page.dart
lib/services/attendance_correction_service.dart
lib/core/models/attendance_correction_request.dart
```

## Instruksi implementasi

1. Tampilkan tombol `Ajukan Koreksi` juga untuk item `ALPA` atau hari kerja yang tidak punya attendance record.
2. Form koreksi harus bisa dibuka dengan `oldAttendance == null` atau map kosong.
3. Jika item ALPA dibuka dari History, kirim `initialDate` sesuai tanggal item.
4. Jika `oldAttendance` kosong, tampilkan info:

```text
Belum ada data presensi pada tanggal ini. Ajukan koreksi jika Anda lupa absen atau data belum tercatat.
```

5. Setelah submit koreksi dari ALPA atau tanpa attendance, arahkan user ke halaman `Status Pengajuan` atau tampilkan instruksi jelas bahwa request bisa dipantau di Status Pengajuan.
6. Jangan mengubah attendance final dari mobile.
7. Semua request koreksi tetap status awal:

```text
pending
```

## Duplikat overlap

Perbaiki `_ensureNoActiveRequest` agar tipe koreksi yang overlap dianggap konflik.

Aturan overlap:

```text
masuk konflik dengan masuk dan masuk_pulang
pulang konflik dengan pulang dan masuk_pulang
masuk_pulang konflik dengan masuk, pulang, dan masuk_pulang
```

Status yang dianggap aktif:

```text
pending
pending_admin
processing
approved
validated
```

Status `rejected`, `declined`, `cancelled` tidak dianggap aktif.

## Acceptance criteria

- Item ALPA di History bisa membuka form koreksi.
- Form koreksi tetap aman walau `oldAttendance` kosong.
- User bisa submit request koreksi dari tanggal ALPA.
- Duplikat overlap dicegah.
- Attendance final tidak berubah dari mobile.
- `flutter analyze` pass.

---

# PATCH-POLISH-02 - Detail Status Pengajuan

## Masalah

Halaman `Status Pengajuan` sudah ada, tetapi card masih ringkas. User perlu bisa tap item untuk melihat detail lengkap.

## File target

```text
lib/features/requests/request_status_page.dart
lib/features/requests/request_status_detail_sheet.dart
lib/core/models/request_status_item.dart
lib/services/request_status_service.dart
```

Boleh membuat `request_status_detail_sheet.dart` agar file page tidak terlalu besar.

## Instruksi implementasi

1. Setiap card `Status Pengajuan` bisa ditekan.
2. Saat ditekan, buka bottom sheet/detail page.
3. Detail harus menampilkan data umum:

```text
Jenis pengajuan
Status normalisasi
Status asli/raw status
Tanggal pengajuan
Tanggal target/rentang tanggal
Tanggal diproses jika ada
Catatan user/alasan
Catatan admin
Lampiran/foto bukti jika ada
```

4. Untuk QR tampilkan:

```text
Sebagai Target / Sebagai Helper
Target name / target uid
Helper name / helper uid
Action type: masuk/pulang
Photo evidence status
```

5. Untuk Koreksi Presensi tampilkan:

```text
Tanggal koreksi
Tipe koreksi
Jam masuk yang diajukan
Jam pulang yang diajukan
Data presensi lama jika ada
Lampiran jika ada
Admin note jika ada
```

6. Untuk Izin/Sakit/Cuti/Lembur tampilkan:

```text
Jenis pengajuan
Tanggal mulai/selesai
Alasan
Lampiran
Status approval
```

7. Jika data lama tidak lengkap, tampilkan `-`, jangan crash.

## Acceptance criteria

- Tap card membuka detail.
- Detail tampil untuk leave, QR target/helper, dan koreksi.
- Data lama yang kosong tidak crash.
- `flutter analyze` pass.

---

# PATCH-POLISH-03 - Preview foto/lampiran

## Masalah

Status Pengajuan dan Detail Presensi sudah mengetahui `photo_url`, `photo_path`, `attachment_url`, atau `attachment_path`, tetapi user perlu preview yang jelas.

## File target

```text
lib/features/history/attendance_detail_sheet.dart
lib/features/requests/request_status_detail_sheet.dart
lib/services/storage_service.dart
```

Boleh membuat reusable widget:

```text
lib/widgets/attachment_preview.dart
lib/widgets/photo_preview_sheet.dart
```

## Instruksi implementasi

1. Jika ada `photo_url` atau `attachment_url`, tampilkan thumbnail atau tombol `Lihat Foto`.
2. Jika hanya ada Storage path, gunakan `StorageService.downloadUrl(path)`.
3. Saat user menekan preview, tampilkan fullscreen/bottom sheet preview gambar.
4. Jika URL gagal diambil, tampilkan:

```text
Foto/lampiran belum bisa dimuat.
```

5. Jangan crash saat URL kosong, path kosong, atau Storage gagal.
6. Jangan menambah dependency image viewer baru jika Flutter bawaan cukup.
7. Preview berlaku untuk:

```text
Foto presensi masuk/pulang
Foto QR titip absen
Lampiran izin/sakit/cuti/lembur
Lampiran koreksi presensi
```

## Acceptance criteria

- Foto presensi bisa dibuka preview besar.
- Foto QR bisa dibuka dari Status Pengajuan detail.
- Lampiran pengajuan bisa dibuka dari Status Pengajuan detail.
- Data kosong/gagal load tidak crash.
- `flutter analyze` pass.

---

# PATCH-POLISH-04 - Lihat lokasi dari detail presensi

## Masalah

Detail Presensi sudah menampilkan koordinat, jarak, radius, dan flag lokasi. User perlu tombol untuk membuka lokasi.

## File target

```text
lib/features/history/attendance_detail_sheet.dart
lib/features/company_webview/company_webview_page.dart jika reusable
assets/maps.html jika memang perlu dan sudah ada
```

## Instruksi implementasi

1. Tambahkan tombol:

```text
Lihat Lokasi
```

pada Detail Presensi jika latitude dan longitude tersedia.

2. Opsi implementasi aman:

```text
A. Buka URL Google Maps eksternal dengan latitude/longitude
B. Atau buka WebView map internal jika project sudah punya helper map yang aman
```

Pilih yang paling minim risiko.

3. Jika membuka URL eksternal butuh dependency baru, jangan tambahkan dulu. Gunakan WebView internal jika sudah tersedia.
4. Jika tidak ada koordinat, tampilkan:

```text
Lokasi tidak tersedia.
```

5. Detail lokasi harus menampilkan:

```text
Latitude
Longitude
Distance meter
Radius meter
Office latitude/longitude jika tersedia
Geofence status
Location risk level
```

## Acceptance criteria

- Tombol Lihat Lokasi muncul jika koordinat tersedia.
- Tidak crash jika koordinat kosong.
- User bisa melihat lokasi dari detail presensi.
- `flutter analyze` pass.

---

# PATCH-POLISH-05 - Warning lokasi/foto lebih jelas

## Masalah

Flag lokasi dan kualitas foto sudah disimpan, tapi warning perlu lebih terlihat di UI agar user paham data akan divalidasi admin.

## File target

```text
lib/features/attendance/camera_presence_page.dart
lib/features/proxy_qr/proxy_qr_camera_page.dart
lib/features/history/attendance_detail_sheet.dart
lib/services/attendance_service.dart
lib/services/qr_service.dart
lib/core/models/presence_submission_result.dart
```

## Instruksi implementasi

1. Pada preview foto, jika `photoQuality.status == warning`, tampilkan warning card kecil:

```text
Foto terlihat kurang jelas. Anda tetap bisa mengirim, tetapi admin mungkin perlu validasi tambahan.
```

2. Tombol `Ulangi Foto` harus lebih terlihat saat kualitas foto warning.
3. Setelah submit attendance/QR, jika result punya warning lokasi/foto, tampilkan ringkasan:

```text
Presensi berhasil dikirim dengan catatan validasi.
```

Lalu tampilkan detail warning di toast/snackbar/bottom sheet ringan.

4. Jika lokasi akurasi buruk atau mock location terdeteksi, tampilkan warning sebelum/sesudah submit sesuai data yang tersedia.
5. Jangan blokir lokasi warning selama user masih dalam radius, kecuali flow lama memang sudah menolak di luar radius.
6. Jangan blokir foto warning. Blokir hanya jika foto invalid/rusak.
7. Pastikan raw exception tidak tampil ke user.

## Acceptance criteria

- Warning foto terlihat sebelum submit.
- Warning lokasi/foto terlihat setelah submit jika ada.
- Foto warning tetap bisa dikirim.
- Foto invalid tetap ditolak.
- Lokasi warning tidak merusak geofence lama.
- `flutter analyze` pass.

---

# PATCH-POLISH-06 - Badge pending pengajuan

## Masalah

User perlu tahu kalau ada pengajuan yang masih pending tanpa membuka halaman Status Pengajuan.

## File target

```text
lib/features/profile/profile_page.dart
lib/features/home/home_page.dart jika ingin shortcut di Home
lib/services/request_status_service.dart
```

## Instruksi implementasi

1. Tambahkan method di `RequestStatusService` untuk menghitung jumlah pending user:

```text
pending leave + pending QR + pending correction
```

2. Di Profile menu `Status Pengajuan`, tampilkan badge kecil jika pending > 0:

```text
Status Pengajuan    3 pending
```

atau badge bulat angka:

```text
3
```

3. Jangan membuat Profile jadi lambat. Gunakan FutureBuilder ringan atau load async terpisah.
4. Jika service gagal membaca data, jangan crash dan jangan tampilkan badge.
5. Opsional: tambahkan shortcut kecil di Home, tetapi jangan membuat Home terlalu ramai.

## Acceptance criteria

- Badge pending muncul di Profile jika ada pending.
- Badge tidak muncul jika 0 atau gagal load.
- Tidak mengganggu menu Profile lain.
- `flutter analyze` pass.

---

# PATCH-POLISH-07 - Filter jenis pengajuan

## Masalah

Status Pengajuan baru punya filter status. User juga perlu filter berdasarkan jenis pengajuan.

## File target

```text
lib/features/requests/request_status_page.dart
lib/core/models/request_status_item.dart
```

## Instruksi implementasi

Tambahkan filter jenis:

```text
Semua Jenis
Izin
Sakit
Cuti
Lembur
QR
Koreksi
```

Catatan:

- `RequestStatusKind.leave` perlu dibedakan dari `kindLabel` atau field type agar izin/sakit/cuti/lembur bisa difilter.
- QR target/helper masuk filter `QR`.
- Correction masuk filter `Koreksi`.

UI boleh berupa horizontal chips di bawah filter status.

Filter final adalah gabungan:

```text
filter status AND filter jenis
```

Contoh:

```text
Pending + QR = hanya QR pending
Disetujui + Cuti = hanya cuti disetujui
Semua + Semua Jenis = semua item
```

## Acceptance criteria

- Filter status lama tetap jalan.
- Filter jenis berjalan.
- Kombinasi filter status + jenis berjalan.
- Empty state menyesuaikan filter.
- `flutter analyze` pass.

---

# PATCH-POLISH-08 - Fix Detail Presensi: lokasi harus dibaca dari nested `masuk/pulang`

## Masalah

Pada halaman `Detail Presensi`, bagian `Detail Lokasi` bisa tampil kosong walaupun data lokasi sebenarnya ada.

Penyebabnya: field lokasi disimpan di node aksi:

```text
attendance/{companyId}/{uid}/{date}/masuk
attendance/{companyId}/{uid}/{date}/pulang
```

Namun UI detail membaca lokasi dari root harian:

```text
attendance/{companyId}/{uid}/{date}
```

Akibatnya field berikut tampil `-`:

```text
Latitude
Longitude
Distance meter
Radius meter
Office latitude/longitude
Geofence status
Location risk level
```

Padahal data ada di nested `masuk` atau `pulang`.

## File target

```text
lib/features/history/attendance_detail_sheet.dart
```

Boleh membuat helper kecil di file yang sama. Jangan refactor besar.

## Instruksi implementasi

1. Ambil nested record:

```dart
final masuk = _nestedMap(attendance['masuk']);
final pulang = _nestedMap(attendance['pulang']);
```

2. Buat helper untuk memilih record utama:

```dart
Map<String, dynamic> _primaryAttendanceRecord(
  Map<String, dynamic> attendance,
  Map<String, dynamic>? masuk,
  Map<String, dynamic>? pulang,
) {
  return masuk ?? pulang ?? attendance;
}
```

3. Gunakan `primaryRecord` untuk field berikut:

```text
latitude
longitude
accuracy
location_accuracy
distance_meter
radius_meter
office_latitude
office_longitude
geofence_status
location_risk_level
location_warning
location_mock_warning
location_accuracy_warning
mock_location_detected
location_mock_detected
office_id
office_name
department_id
department_name
sub_department_id
sub_department_name
group_id
group_name
validation_status
status
source
method
photo_quality_status
photo_quality_warning
```

4. Helper UI seperti `_locationValue`, `_distanceBadge`, `_locationColor`, `_officeValue`, `_groupValue`, `_statusChipColor`, `_sourceLabel`, dan `_methodLabel` harus membaca dari record yang benar.
5. Jika `masuk` dan `pulang` sama-sama ada, default tampilan ringkas boleh memakai `masuk` sebagai lokasi utama.
6. Tambahkan section detail yang lebih jelas jika memungkinkan:

```text
Detail Lokasi Clock In
Detail Lokasi Clock Out
```

Jika tidak sempat, minimal pastikan lokasi utama tidak kosong bila data ada di `masuk`.

7. Untuk record lama yang memang tidak punya lokasi, tetap tampilkan `Lokasi tidak tersedia.` dan jangan crash.
8. Tombol `Lihat Lokasi` harus memakai koordinat dari record yang benar.
9. Jangan mengubah struktur data RTDB.
10. Jangan mengubah `AttendanceService.submitSelfieAttendance`, karena penyimpanan nested `masuk/pulang` sudah benar.

## Acceptance criteria

- Detail Presensi untuk data baru menampilkan latitude/longitude dari `masuk` atau `pulang`.
- Distance meter, radius meter, geofence status, dan location risk level tidak kosong jika data ada.
- Unit kerja mengambil data dari nested record jika root kosong.
- Validasi dan method/source tidak salah kosong jika field ada di nested record.
- Jika hanya `pulang` yang ada, lokasi memakai data `pulang`.
- Jika data lama tidak punya lokasi, UI tetap aman dan menampilkan `Lokasi tidak tersedia.`
- `flutter analyze` pass.

---

# Laporan akhir Codex

Setelah selesai, Codex wajib menulis laporan:

```text
## Summary
- Fitur yang dikerjakan:
- File yang diubah:
- File baru:

## Validation
- flutter analyze: pass/fail

## Package Check
- namespace:
- applicationId:

## Manual Build
- Tidak dijalankan oleh Codex. Build dilakukan manual oleh user.

## Notes
- Risiko tersisa:
- Hal yang perlu dicek manual oleh user:
```

Jangan menulis hasil build karena build tidak diminta.

---

## Urutan pengerjaan final

```text
1. Koreksi Presensi dari ALPA dan duplikat overlap
2. Detail Status Pengajuan
3. Preview foto/lampiran
4. Lihat lokasi dari detail presensi
5. Warning lokasi/foto lebih jelas
6. Badge pending pengajuan
7. Filter jenis pengajuan
8. Fix Detail Presensi agar lokasi membaca nested masuk/pulang
9. flutter analyze
10. Laporan akhir
```
