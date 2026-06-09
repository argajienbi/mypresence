# PATCH.md - MYPRESENCE Flutter App

Dokumen ini adalah instruksi kerja untuk Codex pada repo `argajienbi/mypresence`.

Peran Codex: implementer teknis untuk Flutter app.
Peran ChatGPT: orkestrator, penjaga urutan kerja, validasi hasil, dan sinkronisasi dengan dashboard admin.

Jangan melakukan refactor besar, jangan mengganti stack, jangan mengganti package, dan jangan menghapus fitur yang sudah berjalan. Tugas kali ini adalah memperbaiki bagian yang sudah teridentifikasi, bukan mengubah proyek menjadi eksperimen baru yang nanti menangis di `flutter analyze`.

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

Tugas Codex bukan rename package.

---

## Aturan validasi wajib

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

Build akan dilakukan manual oleh user. Jangan menambahkan instruksi build di laporan akhir. Ya, akhirnya ada pembagian kerja yang masuk akal, kejadian langka di dunia software.

---

## Prinsip kerja wajib

1. Kerjakan bertahap sesuai prioritas di bawah.
2. Jangan menghapus flow login, splash, home, history, profile, attendance selfie, QR, notification, schedule, atau service Firebase yang sudah ada.
3. Jangan mengganti struktur besar aplikasi tanpa kebutuhan jelas.
4. Jangan mengganti package Android dari `com.mypresence`.
5. Jika membuat file baru, pastikan import dan navigation lengkap.
6. Jangan membuat konfigurasi Firebase palsu.
7. Jangan commit secret baru, keystore, file credential pribadi, service account, `.env`, atau file rahasia lain.
8. Jangan menambah dependency baru kecuali benar-benar tidak bisa dihindari. Prioritaskan dependency yang sudah ada.
9. Validasi akhir cukup `flutter analyze`.

---

## Status pekerjaan sebelumnya

Pekerjaan yang sudah dianggap selesai dan jangan diulang kecuali ada bug langsung:

```text
[OK] Package tetap com.mypresence
[OK] Firebase config Android sudah konsisten
[OK] QR titip absen tidak langsung submit
[OK] QR lanjut ke halaman kamera
[OK] Foto QR diupload ke Firebase Storage
[OK] QR request membawa photo_url dan photo_path
[OK] Release signing lokal sudah mulai rapi
```

Fokus patch berikut adalah catatan baru di bawah.

---

# PATCH-FLUTTER-NEXT-01 - Koreksi logika QR helper: office, geofence, dan schedule target

## Masalah

Flow QR titip absen sudah memakai foto. Namun ada potensi salah logic:

1. Geofence QR masih memakai kantor/radius `helperSession`.
2. Schedule QR request masih memakai schedule helper.
3. Kalau helper dan target beda kantor dalam company yang sama, request bisa menyesatkan.

Presensi bukan teleportasi antar-cabang. Jangan biarkan user kantor B menolong QR user kantor A kecuali memang ada aturan eksplisit dari admin, dan saat ini belum ada.

## Target aturan

Untuk tahap ini, gunakan aturan paling aman:

```text
QR titip absen hanya boleh dilakukan jika helper dan target memiliki office_id yang sama.
```

Jika beda kantor, tampilkan error ramah:

```text
QR hanya bisa digunakan oleh karyawan di kantor yang sama.
```

## File target

- `lib/services/qr_service.dart`
- `lib/features/proxy_qr/proxy_attendance_page.dart`
- `lib/features/proxy_qr/proxy_qr_camera_page.dart`
- `lib/core/firebase_paths.dart` bila perlu
- `lib/core/error_mapper.dart` bila perlu

## Instruksi implementasi

1. Di proses validasi target QR, cek:

```text
helperSession.officeId == target['office_id']
```

2. Jika target `office_id` kosong, tampilkan error:

```text
Data kantor target belum lengkap. Hubungi admin.
```

3. Jika helper `officeId` kosong, tampilkan error:

```text
Data kantor akun Anda belum lengkap. Hubungi admin.
```

4. Jika beda `office_id`, tolak request.
5. Simpan field eksplisit pada request QR:

```text
helper_office_id
helper_office_name
helper_department_id
helper_department_name
helper_sub_department_id
helper_sub_department_name
helper_group_id
helper_group_name

target_office_id
target_office_name jika tersedia
target_department_id
target_department_name jika tersedia
target_sub_department_id
target_sub_department_name jika tersedia
target_group_id
target_group_name jika tersedia
```

6. Jangan menaruh schedule helper sebagai schedule target di root QR request.
7. Jika schedule tetap perlu disimpan untuk audit, simpan sebagai helper schedule dengan prefix jelas:

```text
helper_schedule_source
helper_shift_id
helper_shift_name
helper_timetable_id
helper_timetable_name
```

8. Root field schedule target harus dibiarkan kosong atau diberi status pending resolusi admin, misalnya:

```text
schedule_source: pending_admin_resolution
schedule_ready: false
```

9. Attendance final tetap harus diselesaikan di admin web dengan resolve schedule berdasarkan `target_uid`, bukan `helper_uid`.
10. Jangan merusak validasi yang sudah ada:

```text
QR beda perusahaan ditolak
Helper tidak bisa scan QR sendiri
Target harus active
QR token harus cocok dan active
Request harus membawa photo_url dan photo_path
```

## Acceptance criteria

- QR beda company tetap ditolak.
- QR milik sendiri tetap ditolak.
- QR inactive/token mismatch tetap ditolak.
- QR beda office ditolak.
- QR request menyimpan data helper dan target dengan jelas.
- Root schedule QR tidak lagi menyesatkan sebagai schedule helper.
- `flutter analyze` pass.

---

# PATCH-FLUTTER-NEXT-02 - Perbaiki live photo absen: layout tombol Ulangi dan crash kamera

## Masalah layout

Pada halaman live foto absen setelah foto diambil, tombol `Ulangi` terlihat tidak rapi:

- teks pecah menjadi dua baris;
- ikon dan label tidak sejajar;
- area bawah kurang proporsional;
- tombol utama upload terlalu dominan sedangkan tombol ulangi terlihat sempit.

## Masalah crash

Ada crash saat tombol kamera ditekan cepat/berulang, sekitar 3 kali:

```text
CameraException(IllegalArgumentException)
No supported surface combination is found for camera device.
May be attempting to bind too many use cases.
```

Ini biasanya terjadi karena `takePicture()`, switch kamera, re-init camera, atau dispose/init controller saling bertabrakan. Android CameraX memang murah hati dalam memberi pesan error sepanjang novel murahan.

## File target

- `lib/features/attendance/camera_presence_page.dart`
- `lib/features/proxy_qr/proxy_qr_camera_page.dart`
- `lib/core/error_mapper.dart`
- widget terkait jika ada reusable camera bottom sheet

## Instruksi layout

1. Perbaiki tombol `Ulangi` agar tidak pecah baris.
2. Buat layout pasca-foto lebih rapi.
3. Saat foto sudah diambil, gunakan layout review khusus:

```text
[Ulangi Foto]    [Kirim / Upload]
```

atau tetap tombol upload bulat di tengah, tetapi tombol `Ulangi` harus punya lebar cukup dan teks satu baris.

4. Icon kecil, teks rapi, spacing konsisten.
5. Bottom sheet tidak boleh terlalu tinggi sampai menutup preview foto berlebihan.
6. Label lokasi dan jam tetap terlihat.
7. Teks bantuan tetap ada, misalnya:

```text
Periksa hasil foto, lalu kirim presensi.
```

## Instruksi anti-crash kamera

1. Disable tombol capture ketika:

```text
_initializing == true
_capturing == true
_submitting == true
controller == null
controller.value.isInitialized == false
```

2. Disable tombol switch/retake ketika:

```text
_capturing == true
_submitting == true
_initializing == true
```

3. Tambahkan guard agar `takePicture()` tidak bisa berjalan paralel:

```dart
if (_capturing || _submitting || _captureLocked) return;
```

4. Tambahkan debounce/throttle minimal 800-1200 ms untuk tombol kamera.
5. Pastikan `onTap` tombol kamera menjadi `null` saat proses capture berjalan.
6. Jangan re-init camera ketika controller lama belum selesai dispose.
7. Saat lifecycle pause/resume, pastikan tidak ada controller disposed yang masih dipakai.
8. Setelah `controller.dispose()`, set `_controller = null` bila aman.
9. Semua operasi async camera harus cek `mounted` sebelum `setState`.
10. Tangkap `CameraException` dan tampilkan pesan ramah:

```text
Kamera sedang memproses. Tunggu sebentar lalu coba lagi.
```

atau:

```text
Kamera belum siap. Jangan tekan tombol berulang.
```

11. Jangan tampilkan raw error panjang ke user.
12. Jika perlu, turunkan `ResolutionPreset.high` menjadi `ResolutionPreset.medium` untuk halaman yang crash, tetapi hanya jika guard/debounce belum cukup atau device tertentu tetap bermasalah.

## Acceptance criteria

- Tombol `Ulangi` terlihat rapi dan tidak pecah baris.
- Tombol kamera tidak bisa ditekan berulang saat proses capture.
- Tidak ada `takePicture()` paralel.
- Switch camera tidak bisa ditekan saat capture/submitting.
- Raw `CameraException` tidak tampil ke user.
- Halaman attendance camera dan QR camera sama-sama aman.
- `flutter analyze` pass.

---

# PATCH-FLUTTER-NEXT-03 - Kalender riwayat harus menampilkan real presensi user berdasarkan jadwal

## Masalah

Halaman history/riwayat saat ini hanya membaca data presensi yang sudah ada di RTDB. Jika user punya jadwal kerja tetapi tidak absen dan tidak ada izin/sakit/cuti, tanggal itu tidak otomatis dihitung sebagai `ALPA`.

Kalender 1 bulan juga belum benar-benar schedule-aware. Ini membuat kalender terlihat sopan tapi tidak jujur, seperti laporan proyek yang semua statusnya hijau padahal server terbakar.

## Target logic

Jika user sudah ditentukan jadwal kerja dari tanggal mulai sampai akhir kontrak/akhir assignment, kalender 1 bulan harus menampilkan status real presensi harian.

Untuk setiap tanggal dalam bulan:

```text
1. Resolve jadwal user pada tanggal itu.
2. Cek apakah tanggal itu hari kerja.
3. Cek apakah ada leave approved: izin/sakit/cuti.
4. Cek apakah ada attendance masuk/pulang.
5. Tentukan status final harian.
```

## Urutan prioritas status harian

Gunakan urutan ini:

```text
1. IZIN / SAKIT / CUTI approved
2. TELAT jika ada absen masuk terlambat
3. HADIR jika ada absen masuk atau pulang
4. ALPA jika hari kerja sudah lewat dan tidak ada presensi/keterangan
5. LIBUR/OFF jika schedule menyatakan bukan hari kerja atau holiday
6. JADWAL jika tanggal masa depan punya jadwal tapi belum waktunya absen
7. TANPA DATA jika tidak ada jadwal dan tidak ada data
```

Catatan penting:

- Jangan tandai tanggal masa depan sebagai `ALPA`.
- Untuk hari ini, tandai `ALPA` hanya jika check-in window sudah lewat dan tidak ada presensi/keterangan.
- Weekend tidak otomatis libur jika schedule mengatakan hari itu workday.
- Schedule resolver harus menjadi sumber kebenaran, bukan asumsi Sabtu/Minggu.

## File target

- `lib/features/history/history_page.dart`
- `lib/services/attendance_service.dart`
- `lib/services/leave_service.dart`
- `lib/services/schedule_service.dart` bila perlu
- `lib/core/utils.dart` bila perlu helper tanggal

## Instruksi implementasi

1. Tambahkan struktur data internal untuk status harian, misalnya:

```dart
class DailyHistoryStatus {
  final DateTime date;
  final String dateKey;
  final String status; // hadir, telat, izin, sakit, cuti, alpa, libur, jadwal, tanpa_data
  final Map<String, dynamic>? attendanceRow;
  final Map<String, dynamic>? leaveRow;
  final DailySchedule? schedule;
}
```

2. Di `_load()` HistoryPage, jangan hanya simpan `_rows`. Bangun list harian 1 bulan berdasarkan semua tanggal bulan tersebut.
3. Gunakan `ScheduleService.resolveRange(session, firstDay, lastDay)` atau helper setara.
4. Ambil attendance map bulanan.
5. Ambil leave approved yang overlap dengan bulan, bukan hanya yang mulai di bulan tersebut.
6. Ambil overtime approved yang overlap dengan bulan jika relevan.
7. Leave multi-hari wajib mewarnai semua tanggal dari `date_start` sampai `date_end`.
8. Leave yang mulai bulan sebelumnya dan berakhir di bulan ini tetap harus tampil.
9. Jika tanggal adalah hari kerja sesuai schedule dan tidak ada attendance/leave, tampilkan `ALPA` untuk tanggal yang sudah lewat.
10. Jika user telat masuk, tampilkan `TELAT` meskipun ada data pulang. Jangan kalah oleh status hadir lengkap.
11. Summary bulan harus dihitung dari daily status final, bukan hanya dari row attendance mentah.
12. Daftar Presensi juga harus bisa menampilkan item `ALPA` untuk hari kerja kosong.
13. Pada item `ALPA`, tampilkan keterangan jelas:

```text
Tidak ada presensi dan tidak ada keterangan.
```

14. Pada item `LIBUR/OFF`, boleh tidak ditampilkan di daftar utama agar daftar tidak terlalu ramai, tetapi kalender tetap harus mewarnai.
15. Jika tetap menampilkan off/libur, pisahkan visualnya agar tidak membingungkan dengan alpa.

## Perbaikan bug warna kalender

Saat ini kemungkinan telat bisa kalah oleh hadir lengkap. Perbaiki urutan:

```text
if telat -> orange
else if hadir -> green
```

Jangan lakukan:

```text
if masuk && pulang -> green dulu
lalu cek telat setelahnya
```

## Acceptance criteria

- Kalender 1 bulan menampilkan `ALPA` pada hari kerja tanpa presensi/keterangan.
- Tanggal masa depan tidak dihitung `ALPA`.
- Hari ini tidak dihitung `ALPA` sebelum waktu check-in relevan lewat.
- `TELAT` tetap orange meskipun ada data pulang.
- Leave multi-hari muncul di semua tanggal dalam range.
- Summary Alpha dihitung dari jadwal kerja kosong.
- Daftar Presensi bisa menampilkan item ALPA.
- `flutter analyze` pass.

---

# PATCH-FLUTTER-NEXT-04 - Relayout halaman History/Riwayat agar daftar presensi lebih terlihat

## Masalah

Panel `Ringkasan Bulan Ini` terlalu besar dan memakan ruang vertikal. Akibatnya daftar presensi terdorong ke bawah, seolah data utama disembunyikan demi kartu statistik yang terlalu percaya diri.

## Target UI

Ubah `Ringkasan Bulan Ini` dari grid besar menjadi horizontal scroll compact.

Contoh arah layout:

```text
Ringkasan Bulan Ini
[Hadir 12] [Telat 2] [Izin 1] [Sakit 0] [Cuti 1] [Lembur 3] [Alpa 2]
```

## File target

- `lib/features/history/history_page.dart`

## Instruksi implementasi

1. Ganti `_SummaryGrid` dari `GridView.builder` menjadi horizontal list/strip.
2. Boleh rename menjadi:

```text
_SummaryHorizontalList
_SummaryStrip
_CompactSummaryList
```

3. Setiap card tetap bisa diklik untuk membuka detail tanggal.
4. Card dibuat compact:

```text
height: sekitar 72-86
width: sekitar 86-110
icon: 16-20
angka: 18-22
label: 10-12
```

5. Gunakan `SingleChildScrollView(scrollDirection: Axis.horizontal)` atau `ListView.separated` horizontal dengan tinggi fixed.
6. Jangan menghapus summary. Cukup ringkas tampilannya.
7. Pastikan `Daftar Presensi` muncul lebih cepat di viewport tanpa scroll panjang.
8. Pastikan tidak ada overflow pada layar kecil.

## Acceptance criteria

- Panel summary tidak lagi memakan banyak tinggi layar.
- Summary card tampil horizontal dan compact.
- Daftar Presensi lebih mudah terlihat.
- Semua summary card tetap bisa diklik.
- `flutter analyze` pass.

---

# PATCH-FLUTTER-NEXT-05 - Isi halaman Syarat dan Ketentuan di menu Profil

## Masalah

Halaman `Syarat dan Ketentuan` di menu Profil harus diisi. Jangan biarkan placeholder kosong seperti janji dokumentasi yang tidak pernah ditulis.

## File target

Cari file yang sudah ada lebih dulu:

- `lib/features/profile/profile_page.dart`
- `lib/features/profile/terms_page.dart`
- `lib/features/profile/terms_conditions_page.dart`
- file sejenis di folder profile/settings

Jika belum ada halaman, buat file baru yang rapi, misalnya:

```text
lib/features/profile/terms_page.dart
```

## Konten minimal

Isi dengan bahasa Indonesia sederhana dan sesuai konteks aplikasi presensi.

Bagian yang harus ada:

```text
1. Penggunaan aplikasi MYPRESENCE
2. Ketentuan akun karyawan
3. Ketentuan presensi masuk dan pulang
4. Penggunaan lokasi / GPS
5. Penggunaan kamera dan foto selfie
6. Ketentuan QR titip absen
7. Ketentuan izin, sakit, cuti, dan lembur
8. Validasi admin
9. Larangan manipulasi data presensi
10. Perubahan data oleh admin/perusahaan
11. Batasan tanggung jawab aplikasi
12. Persetujuan pengguna
```

## Arahan gaya UI

1. Gunakan layout yang konsisten dengan halaman Profil.
2. Pakai section title dan paragraph pendek.
3. Jangan pakai paragraf hukum terlalu panjang.
4. Pastikan nyaman dibaca di layar kecil.
5. Tambahkan catatan bahwa kebijakan final mengikuti aturan perusahaan/admin masing-masing.

## Acceptance criteria

- Menu Profil bisa membuka halaman Syarat dan Ketentuan.
- Halaman tidak kosong.
- Konten mudah dibaca.
- Tidak ada overflow.
- `flutter analyze` pass.

---

# PATCH-FLUTTER-NEXT-06 - Isi halaman Pusat Bantuan di menu Profil

## Masalah

Halaman `Pusat Bantuan` di menu Profil harus diisi dengan panduan penggunaan aplikasi.

## File target

Cari file yang sudah ada lebih dulu:

- `lib/features/profile/profile_page.dart`
- `lib/features/profile/help_center_page.dart`
- `lib/features/profile/help_page.dart`
- file sejenis di folder profile/settings

Jika belum ada halaman, buat file baru yang rapi, misalnya:

```text
lib/features/profile/help_center_page.dart
```

## Konten minimal

Isi Pusat Bantuan dengan panduan singkat:

```text
1. Cara absen masuk
2. Cara absen pulang
3. Cara menggunakan QR titip absen
4. Cara mengajukan izin
5. Cara mengajukan sakit
6. Cara mengajukan cuti
7. Cara mengajukan lembur
8. Kenapa lokasi harus aktif
9. Kenapa kamera harus diizinkan
10. Solusi jika gagal absen
11. Solusi jika di luar radius kantor
12. Solusi jika QR tidak valid
13. Solusi jika notifikasi tidak muncul
14. Cara menghubungi admin perusahaan
```

## Arahan gaya UI

1. Gunakan format FAQ atau section list.
2. Gunakan bahasa sederhana.
3. Buat jawaban pendek, praktis, dan langsung ke solusi.
4. Hindari teks panjang tanpa jeda.
5. Jika ada nomor kontak admin belum tersedia, tulis:

```text
Hubungi admin perusahaan Anda untuk bantuan lebih lanjut.
```

## Acceptance criteria

- Menu Profil bisa membuka halaman Pusat Bantuan.
- Halaman tidak kosong.
- Konten membantu user memahami alur presensi.
- Tidak ada overflow.
- `flutter analyze` pass.

---

# PATCH-FLUTTER-NEXT-07 - Catatan sinkronisasi admin_web, jangan diimplementasikan di repo Flutter

Bagian ini hanya catatan sinkronisasi untuk orkestrator/admin_web. Jangan ubah repo admin dari repo Flutter.

Catatan untuk patch admin_web berikutnya:

```text
[ADMIN TODO] Admin approval QR harus resolve schedule berdasarkan target_uid, bukan helper_uid.
[ADMIN TODO] Admin approval QR harus membaca dan menampilkan photo_url/photo_path.
[ADMIN TODO] Notification channel functions masih mypresensi_high_importance_channel, sementara mobile memakai mypresence_high_importance_channel.
```

Codex cukup memastikan data Flutter menyediakan field yang dibutuhkan admin.

---

## Laporan akhir yang wajib diberikan Codex

Setelah mengerjakan, buat ringkasan:

```text
## Summary
- Perubahan utama:
- File yang diubah:
- File baru:

## Validation
- flutter analyze: pass/fail

## Package Check
- namespace:
- applicationId:
- google-services package:

## Manual Build
- Tidak dijalankan oleh Codex. Build akan dilakukan manual oleh user.

## Notes
- Hal yang butuh tindakan user:
- Risiko yang tersisa:
```

Jangan tulis hasil `flutter build`, karena memang tidak diminta.

---

## Urutan pengerjaan

Kerjakan berurutan:

```text
1. PATCH-FLUTTER-NEXT-01 - QR helper office/geofence/schedule target
2. PATCH-FLUTTER-NEXT-02 - live photo layout + anti-crash camera
3. PATCH-FLUTTER-NEXT-03 - kalender real presensi schedule-aware
4. PATCH-FLUTTER-NEXT-04 - relayout history summary horizontal
5. PATCH-FLUTTER-NEXT-05 - isi Syarat dan Ketentuan
6. PATCH-FLUTTER-NEXT-06 - isi Pusat Bantuan
7. Jalankan flutter analyze
8. Tulis laporan akhir
```

Jangan rename package. Jangan build. Jangan redesign total. Jangan mengubah admin_web dari repo ini.
