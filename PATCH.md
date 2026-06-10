# PATCH.md - MYPRESENCE Flutter App Feature Roadmap

Dokumen ini adalah instruksi kerja untuk Codex pada repo `argajienbi/mypresence`.

Peran Codex: implementer teknis Flutter app.
Peran ChatGPT: orkestrator dan reviewer.

Tujuan patch ini adalah menambahkan fitur baru secara bertahap tanpa merusak fitur yang sudah berjalan.

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
3. Jangan mengganti struktur database yang sudah dipakai tanpa alasan kuat.
4. Jika membuat path baru, gunakan helper di `lib/core/firebase_paths.dart`.
5. Jika membuat service baru, pisahkan logic Firebase dari widget UI.
6. Jika membuat halaman baru, pastikan navigasi dari halaman terkait jelas dan tidak merusak navigation lama.
7. Jangan menambahkan dependency baru kecuali benar-benar diperlukan.
8. Semua fitur write harus bersifat request/pending jika butuh admin approval. Mobile app tidak boleh langsung mengubah data final yang seharusnya divalidasi admin.
9. Semua fitur baru harus tetap aman jika data lama belum punya field baru.
10. Validasi akhir cukup `flutter analyze`.

---

# Urutan fitur tambahan yang harus dikerjakan

Kerjakan sesuai urutan berikut:

```text
1. Status Pengajuan Terpadu
2. Detail Presensi di History
3. Koreksi Presensi
4. Flag Lokasi Mencurigakan
5. Validasi Kualitas Foto
```

Jangan lompat ke fitur berikutnya jika fitur sebelumnya belum stabil.

---

# PATCH-FEATURE-01 - Status Pengajuan Terpadu

## Tujuan

Tambahkan halaman untuk melihat semua status pengajuan user dalam satu tempat.

Fitur ini bersifat read-only untuk data existing, sehingga aman dikerjakan pertama.

## Data yang perlu dibaca

Gunakan data dari:

```text
leave_requests/{companyId}
qr_attendance_requests/{companyId}
attendance_corrections/{companyId} // jika belum ada, siapkan struktur kosong/opsional untuk fitur berikutnya
```

Filter semua data berdasarkan user login:

```text
uid == session.uid
target_uid == session.uid untuk QR attendance
helper_uid == session.uid jika ingin menampilkan request yang user bantu scan
```

## File target yang mungkin perlu dibuat

```text
lib/features/requests/request_status_page.dart
lib/services/request_status_service.dart
lib/core/models/request_status_item.dart
```

Boleh gunakan nama lain yang konsisten dengan struktur project.

## Navigasi

Tambahkan akses dari salah satu lokasi berikut, pilih yang paling aman:

```text
Profile menu
Home quick menu
```

Rekomendasi: tambahkan dari Profile menu agar tidak membuat Home terlalu penuh.

## UI minimal

Halaman `Status Pengajuan` harus punya tab/filter:

```text
Semua
Pending
Disetujui
Ditolak
```

Setiap item menampilkan:

```text
Jenis pengajuan: Izin / Sakit / Cuti / Lembur / QR Titip Absen / Koreksi Presensi
Tanggal pengajuan
Tanggal target / rentang tanggal
Status
Catatan admin jika ada
Lampiran jika ada
Tanggal diproses jika ada
```

## Status mapping

Normalisasi status:

```text
pending / pending_admin / processing -> Pending
approved / validated -> Disetujui
rejected -> Ditolak
```

## QR attendance

Untuk QR attendance, tampilkan dua konteks:

```text
Sebagai Target: user yang dibantu absen
Sebagai Helper: user yang scan QR orang lain
```

Jika item QR punya `photo_url` atau `photo_path`, tampilkan indikator:

```text
Foto bukti tersedia
```

Jika belum ada foto:

```text
Foto bukti belum tersedia
```

## Empty state

Jika tidak ada data:

```text
Belum ada pengajuan.
```

## Acceptance criteria

- User bisa membuka halaman Status Pengajuan.
- Izin/sakit/cuti/lembur tampil dari `leave_requests`.
- QR titip absen tampil dari `qr_attendance_requests`.
- Data lama tanpa field baru tidak menyebabkan crash.
- Filter status berjalan.
- Tidak ada write ke database dari fitur ini.
- `flutter analyze` pass.

---

# PATCH-FEATURE-02 - Detail Presensi di History

## Tujuan

Tambahkan detail presensi saat user menekan item di halaman History/Riwayat.

Fitur ini read-only dan tidak boleh mengubah data attendance.

## File target

```text
lib/features/history/history_page.dart
lib/features/history/attendance_detail_sheet.dart
```

Boleh membuat widget sheet baru agar `history_page.dart` tidak semakin besar.

## Data yang ditampilkan

Untuk item presensi yang punya attendance record, tampilkan:

```text
Tanggal
Status: Hadir / Telat / Alpa / Izin / Sakit / Cuti / Lembur / Jadwal
Jam masuk
Jam pulang
Foto masuk jika ada
Foto pulang jika ada
Metode: selfie / qr
Source: mobile_app / admin_web
Lokasi latitude/longitude
Jarak dari kantor
Radius kantor
Status geofence
Office name / department / group
Jadwal saat itu
Shift name
Timetable name
Work start / work end
Check in window
Check out window
Telat / pulang awal jika ada
```

Untuk item QR, tampilkan tambahan:

```text
QR Helper UID
QR Helper Name
Proxy Request ID / QR Request ID
```

Untuk item ALPA, tampilkan:

```text
Tidak ada presensi dan tidak ada keterangan pada hari kerja ini.
```

Untuk item izin/sakit/cuti, tampilkan:

```text
Jenis pengajuan
Alasan
Status approval
Catatan admin jika ada
Lampiran jika ada
```

## Lokasi

Jika ada latitude/longitude, tampilkan tombol:

```text
Lihat Lokasi
```

Aksi minimal boleh membuka Google Maps external URL atau halaman WebView map yang sudah ada. Jangan menambahkan map logic berat jika belum perlu.

## Foto

Jika `photo_url` ada, tampilkan preview gambar.
Jika hanya `photo_path` ada, gunakan StorageService/get URL jika helper tersedia.
Jika tidak ada foto, tampilkan:

```text
Foto tidak tersedia.
```

## Acceptance criteria

- Tap item History membuka detail.
- Detail tidak crash untuk item ALPA, JADWAL, LIBUR, IZIN, SAKIT, CUTI, dan attendance biasa.
- Foto tampil jika tersedia.
- Lokasi bisa dilihat jika tersedia.
- Tidak ada write database.
- `flutter analyze` pass.

---

# PATCH-FEATURE-03 - Koreksi Presensi

## Tujuan

Tambahkan fitur agar user bisa mengajukan koreksi presensi tanpa langsung mengubah data attendance final.

Mobile app hanya membuat request. Admin yang approve/reject dari dashboard.

## Data path

Tambahkan helper path jika belum ada:

```text
attendance_corrections/{companyId}/{correctionId}
```

Gunakan format ID:

```text
correction_{timestamp}
```

## File target yang mungkin perlu dibuat

```text
lib/features/corrections/attendance_correction_form_page.dart
lib/services/attendance_correction_service.dart
lib/core/models/attendance_correction_request.dart
```

## Akses fitur

Tambahkan dari:

```text
History detail -> Ajukan Koreksi
```

Opsional, juga dari Profile/Status Pengajuan nanti.

## Form minimal

Field form:

```text
Tanggal
Tipe koreksi: Masuk / Pulang / Masuk & Pulang
Jam masuk yang diajukan
Jam pulang yang diajukan
Alasan koreksi
Lampiran opsional
Data presensi lama jika ada
```

Validasi:

```text
Tanggal wajib
Tipe koreksi wajib
Minimal satu jam diajukan sesuai tipe
Alasan wajib
Tidak boleh membuat koreksi duplikat aktif untuk tanggal dan tipe yang sama
```

Status awal:

```text
pending
```

Payload minimal:

```text
correction_id
company_id
uid
user_name
nip
date
correction_type
requested_check_in
requested_check_out
reason
attachment_url
attachment_path
old_attendance_snapshot
status
admin_note
approved_by
approved_by_name
approved_at
rejected_by
rejected_by_name
rejected_at
office_id
office_name
department_id
department_name
sub_department_id
sub_department_name
group_id
group_name
created_at
updated_at
source: mobile_app
```

## Setelah submit

Setelah berhasil submit:

```text
Tampilkan toast sukses
Arahkan ke Status Pengajuan atau kembali ke History detail
```

## Acceptance criteria

- User bisa membuat request koreksi.
- Request tersimpan ke `attendance_corrections/{companyId}/{correctionId}`.
- Attendance final tidak berubah dari mobile app.
- Duplikat pending/approved untuk tanggal dan tipe yang sama dicegah.
- Status Pengajuan Terpadu membaca koreksi presensi jika path sudah ada.
- `flutter analyze` pass.

---

# PATCH-FEATURE-04 - Flag Lokasi Mencurigakan

## Tujuan

Tambahkan audit flag untuk lokasi yang kurang akurat atau mencurigakan saat absen.

Fitur ini jangan langsung memblokir semua presensi. Simpan flag agar admin bisa menilai.

## File target

```text
lib/services/location_service.dart
lib/services/attendance_service.dart
lib/services/qr_service.dart
lib/features/attendance/camera_presence_page.dart jika perlu warning UI
lib/features/proxy_qr/proxy_qr_camera_page.dart jika perlu warning UI
```

## Field audit yang ditambahkan ke attendance selfie dan QR request

Tambahkan field:

```text
location_accuracy
location_accuracy_warning
mock_location_detected
location_mock_warning
location_risk_level
location_warning
```

Jika data provider tersedia, tambahkan:

```text
location_provider
```

## Aturan awal

Gunakan aturan ringan:

```text
accuracy > 50 meter -> warning
accuracy > 100 meter -> high warning
mock location detected -> high warning
```

Jangan langsung blokir presensi jika user masih dalam radius, kecuali app memang sudah menolak di luar radius seperti sekarang.

## Pesan UI

Jika akurasi buruk:

```text
Akurasi lokasi kurang stabil. Data presensi akan diberi tanda untuk validasi admin.
```

Jika mock location terdeteksi:

```text
Lokasi perangkat terdeteksi mencurigakan. Data presensi akan diberi tanda untuk validasi admin.
```

## Acceptance criteria

- Attendance selfie menyimpan flag lokasi.
- QR request menyimpan flag lokasi.
- Jika lokasi normal, risk level `normal` atau kosong.
- Jika akurasi buruk, risk level naik dan warning tersimpan.
- Tidak merusak validasi radius yang sudah ada.
- `flutter analyze` pass.

---

# PATCH-FEATURE-05 - Validasi Kualitas Foto

## Tujuan

Tambahkan validasi kualitas foto dasar sebelum upload presensi.

Tahap ini tidak perlu face recognition atau liveness. Fokus ke validasi ringan agar tidak membuat user gagal absen karena algoritma terlalu agresif.

## File target

```text
lib/features/attendance/camera_presence_page.dart
lib/features/proxy_qr/proxy_qr_camera_page.dart
lib/services/photo_quality_service.dart
```

## Validasi dasar

Cek minimal:

```text
file exists
file size > 0
file size tidak terlalu kecil
image bisa dibaca
resolusi minimal masuk akal
```

Jangan menambahkan dependency baru jika validasi dasar bisa dilakukan dengan API/Dart yang sudah ada.

## UX

Jika foto tidak valid, tampilkan pesan:

```text
Foto belum valid. Silakan ulangi foto.
```

Jika kualitas meragukan tapi masih bisa dipakai, tampilkan warning:

```text
Foto terlihat kurang jelas. Anda tetap bisa mengirim, tetapi admin mungkin perlu validasi tambahan.
```

Gunakan mode warning dulu, bukan blokir keras, kecuali file benar-benar kosong/rusak.

## Field audit tambahan

Simpan ke attendance/QR request jika tersedia:

```text
photo_quality_status
photo_quality_warning
photo_file_size
photo_width
photo_height
```

## Acceptance criteria

- File kosong/rusak tidak diupload.
- Foto valid tetap bisa dikirim.
- Foto meragukan diberi warning, bukan langsung ditolak keras.
- Attendance selfie dan QR photo flow tetap berjalan.
- Tidak ada raw exception ke user.
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
1. Status Pengajuan Terpadu
2. Detail Presensi di History
3. Koreksi Presensi
4. Flag Lokasi Mencurigakan
5. Validasi Kualitas Foto
6. flutter analyze
7. Laporan akhir
```
