# PATCH.md - MYPRESENCE UI, Camera, History Polish Batch

Dokumen ini adalah instruksi kerja untuk Codex pada repo `argajienbi/mypresence`.

Fokus patch ini adalah memperbaiki 8 catatan UI/UX terbaru:

```text
1. Hilangkan lingkaran/oval biru di kamera absen.
2. Relayout popup logout.
3. Tambahkan alert konfirmasi saat tombol back ditekan dari halaman utama.
4. Tingkatkan kualitas kamera, tapi kontrol ukuran file sebelum upload.
5. Hilangkan peringatan “Foto terlihat kurang jelas” dari UI user.
6. Perbaiki teks/status kamera yang tertutup overlay bottom sheet.
7. Ubah Daftar Presensi di Riwayat agar hanya menampilkan 7 hari terakhir sampai hari ini, bukan 1 bulan penuh.
8. Redesign tombol Clock In dan Clock Out menjadi 3D Elevated, sekaligus perbaiki teks terpotong dan icon ceklis duplikat.
```

Jangan mengerjakan fitur lain. Jangan refactor besar. Jangan mengganti package. Jangan mengubah struktur RTDB. Jangan mengubah logic approval, schedule, leave, QR, atau Firebase config. Kita sedang memperbaiki pengalaman pakai, bukan mengundang bug pesta keluarga.

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
RTDB path
AttendanceService submit path, kecuali untuk kompresi file sebelum upload jika dibutuhkan
ScheduleService logic utama
LeaveService
QR approval/request logic
History detail logic selain daftar utama 7 hari
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

# PATCH-UI-01 - Hilangkan lingkaran/oval biru di kamera absen

## Masalah

Pada halaman kamera absen, masih ada overlay oval/lingkaran biru untuk frame wajah. User ingin overlay itu dihilangkan.

## File target

```text
lib/features/attendance/camera_presence_page.dart
lib/features/proxy_qr/proxy_qr_camera_page.dart jika QR camera punya overlay serupa
```

## Instruksi implementasi

1. Hapus widget overlay oval biru pada kamera.
2. Jangan tampilkan frame wajah berbentuk oval.
3. Ubah status awal dari:

```text
Posisikan wajah di dalam oval
```

menjadi:

```text
Pastikan wajah terlihat jelas di kamera.
```

atau:

```text
Arahkan wajah ke kamera, lalu ambil foto.
```

4. Ubah teks bawah dari:

```text
Pastikan wajah berada di tengah oval.
```

menjadi:

```text
Pastikan wajah terlihat jelas sebelum mengambil foto.
```

5. Jangan menghapus preview kamera, header kamera, tombol ganti kamera, tombol foto, atau bottom sheet.

## Acceptance criteria

- Oval/lingkaran biru tidak muncul lagi di kamera absen.
- Tidak ada teks yang menyebut “oval”.
- Kamera tetap bisa capture dan submit.
- `flutter analyze` pass.

---

# PATCH-UI-02 - Relayout popup logout

## Masalah

Popup logout sekarang terlalu polos dan terlihat seperti dialog bawaan. Perlu dibuat lebih modern dan konsisten dengan style MYPRESENCE.

## File target

```text
lib/features/profile/profile_page.dart
```

Jika ingin dipisah:

```text
lib/features/profile/widgets/logout_dialog.dart
```

## Instruksi implementasi

1. Relayout dialog logout menjadi custom dialog/bottom sheet yang rapi.
2. Tambahkan icon logout/peringatan di atas.
3. Judul:

```text
Keluar dari Akun?
```

4. Deskripsi:

```text
Anda akan keluar dari akun ini. Pastikan semua data presensi sudah tersimpan.
```

5. Tombol:

```text
Batal   Keluar
```

6. `Batal` sebagai secondary button.
7. `Keluar` sebagai danger button merah/soft red/gradient red.
8. Radius dialog besar, padding rapi, shadow lembut.
9. Background overlay jangan terlalu pekat.
10. Jangan mengubah logic logout, hanya UI confirmation.

## Acceptance criteria

- Popup logout tampil modern dan rapi.
- Tombol Batal membatalkan logout.
- Tombol Keluar tetap menjalankan logout lama.
- Tidak ada perubahan auth/session selain flow logout existing.
- `flutter analyze` pass.

---

# PATCH-UI-03 - Alert konfirmasi saat tombol back ditekan dari halaman utama

## Masalah

Saat user menekan tombol back Android dari halaman utama, aplikasi langsung keluar. Perlu alert konfirmasi agar tidak keluar tidak sengaja.

## File target

Cari shell/root navigation utama, kemungkinan salah satu:

```text
lib/main.dart
lib/app.dart
lib/app_shell.dart
lib/main_navigation.dart
lib/features/home/home_page.dart
```

Gunakan file yang memang mengatur tab utama Home/Riwayat/Profile.

## Instruksi implementasi

1. Gunakan `PopScope` untuk Flutter terbaru.
2. Alert hanya muncul ketika user berada di halaman/tab utama.
3. Back dari halaman detail/form/kamera tetap kembali normal.
4. Dialog style harus senada dengan popup logout.
5. Judul:

```text
Keluar dari Aplikasi?
```

6. Deskripsi:

```text
Anda yakin ingin menutup MYPRESENCE? Pastikan data presensi atau pengajuan sudah tersimpan.
```

7. Tombol:

```text
Batal   Keluar
```

8. Jika user pilih `Keluar`, tutup aplikasi menggunakan mekanisme aman yang sudah lazim di Flutter, misalnya `SystemNavigator.pop()`.
9. Jangan mengganggu flow kamera, submit presensi, QR, form izin, detail schedule, atau history detail.

## Acceptance criteria

- Tekan back dari tab utama menampilkan konfirmasi.
- Batal menutup dialog saja.
- Keluar menutup aplikasi.
- Back dari page child tetap kembali ke page sebelumnya.
- `flutter analyze` pass.

---

# PATCH-CAMERA-04 - Tingkatkan kualitas kamera, tapi kontrol ukuran file sebelum upload

## Masalah

Kualitas foto di dalam app terlihat lebih rendah dibanding kamera bawaan. Penyebab utama kemungkinan `ResolutionPreset.medium`. Namun menaikkan kualitas kamera akan menaikkan ukuran file Storage, jadi perlu kontrol ukuran.

## File target

```text
lib/features/attendance/camera_presence_page.dart
lib/features/proxy_qr/proxy_qr_camera_page.dart jika ada kamera QR
lib/services/photo_quality_service.dart
lib/services/attendance_service.dart jika kompresi dilakukan sebelum upload
lib/services/qr_service.dart jika QR upload foto juga perlu kompresi
```

## Instruksi implementasi kamera

1. Ubah capture kamera dari `ResolutionPreset.medium` ke kualitas lebih tinggi yang masih stabil:

```dart
ResolutionPreset.high
```

2. Jangan langsung gunakan `veryHigh` atau `max` karena risiko file terlalu besar dan bisa memicu masalah kamera/surface di beberapa device.
3. Jika `ResolutionPreset.high` gagal init di device tertentu, fallback ke `ResolutionPreset.medium`.
4. Jangan mengembalikan bug lama `No supported surface combination`. Jangan menambah image analysis use case baru.
5. Tetap gunakan `imageFormatGroup: ImageFormatGroup.jpeg` jika stabil.

## Instruksi kontrol ukuran file

1. Jangan upload file mentah besar tanpa kontrol ukuran.
2. Target ukuran akhir upload:

```text
maksimal sekitar 1 MB
```

3. Target resolusi:

```text
sisi panjang 1280px - 1600px
```

4. Target JPEG quality:

```text
75 - 85
```

5. Jangan tambah dependency baru jika project belum punya dan ada solusi sederhana. Jika memang perlu dependency untuk compress/resize, tambahkan dengan alasan jelas dan minimal.
6. Jika belum bisa kompres tanpa dependency, minimal:

```text
- naikkan kamera ke high
- validasi file size
- jika file terlalu besar, tampilkan error ramah atau gunakan fallback medium
```

7. Simpan metadata final setelah kompres:

```text
photo_file_size
photo_width
photo_height
photo_quality_status
photo_quality_warning
```

8. Pastikan file yang diupload adalah file final yang sudah dikontrol ukurannya.

## Acceptance criteria

- Foto dari app lebih tajam daripada preset medium lama.
- Upload Storage tidak mengirim file besar tanpa kontrol.
- Target file maksimal sekitar 1 MB jika kompresi tersedia.
- Kamera tetap stabil, tidak crash saat ganti kamera/capture berulang.
- `flutter analyze` pass.

---

# PATCH-CAMERA-05 - Hilangkan peringatan “Foto terlihat kurang jelas” dari UI user

## Masalah

Peringatan “Foto terlihat kurang jelas...” kurang relevan karena validasi sekarang hanya berbasis ukuran/resolusi dasar, bukan deteksi blur/gelap/wajah. User ingin warning ini dihilangkan dari UI.

## File target

```text
lib/services/photo_quality_service.dart
lib/features/attendance/camera_presence_page.dart
lib/features/proxy_qr/proxy_qr_camera_page.dart jika ada
```

## Instruksi implementasi

1. Jangan tampilkan warning card kuning/oranye di bottom sheet kamera untuk `photoQuality.status == warning`.
2. Jangan tampilkan status pill hitam berisi pesan “Foto terlihat kurang jelas...”.
3. Jika validasi menghasilkan warning, tetap izinkan user submit tanpa gangguan UI.
4. Boleh tetap simpan audit field ke database:

```text
photo_quality_status
photo_quality_warning
```

5. Blokir hanya jika foto benar-benar invalid/kosong/rusak/sangat kecil.
6. Jika pesan warning masih diperlukan untuk admin, simpan di payload, tapi jangan tampilkan ke user.
7. Ubah `PhotoQualityService.warningMessage` menjadi lebih netral jika tetap dipakai untuk audit:

```text
Kualitas foto standar. Admin dapat memvalidasi jika diperlukan.
```

atau kosongkan warning untuk data yang masih valid.

## Acceptance criteria

- User tidak melihat warning “Foto terlihat kurang jelas...”.
- Tidak ada warning card kuning/oranye di kamera setelah foto diambil.
- Foto valid tetap bisa dikirim.
- Foto invalid tetap ditolak.
- `flutter analyze` pass.

---

# PATCH-CAMERA-06 - Perbaiki teks/status kamera yang tertutup overlay bottom sheet

## Masalah

Status pill/teks kamera bisa tertutup oleh bottom sheet, terutama saat ada warning card atau panel bawah berubah tinggi.

## File target

```text
lib/features/attendance/camera_presence_page.dart
lib/features/proxy_qr/proxy_qr_camera_page.dart jika ada
```

## Instruksi implementasi

1. Jangan hardcode posisi status pill dengan tinggi bottom sheet yang tidak sesuai isi.
2. Karena warning card UI akan dihapus, pastikan status pill tetap tidak tertutup pada layar kecil.
3. Opsi aman:

```text
- Sembunyikan status pill setelah foto berhasil diambil, karena instruksi sudah ada di bottom sheet.
- Atau posisikan status pill lebih tinggi dan adaptif terhadap bottom sheet.
```

4. Hindari pesan dobel antara status pill dan bottom sheet.
5. Jangan biarkan text berada di belakang bottom sheet.

## Acceptance criteria

- Tidak ada teks/status kamera yang tertutup bottom sheet.
- Setelah foto diambil, UI tetap bersih dan tidak dobel pesan.
- Layout aman di layar kecil.
- `flutter analyze` pass.

---

# PATCH-HISTORY-07 - Daftar Presensi hanya tampilkan 7 hari terakhir sampai hari ini

## Masalah

Menu Riwayat sekarang menampilkan daftar presensi 1 bulan penuh. Tanggal yang belum terjadi/masa depan ikut terlihat sebagai `JADWAL`, sehingga daftar terasa terlalu banyak dan membingungkan.

## File target

```text
lib/features/history/history_page.dart
```

## Instruksi implementasi

1. `Ringkasan Bulan Ini` tetap menghitung 1 bulan.
2. `Lihat Kehadiran 1 Bulan` / kalender tetap menampilkan 1 bulan penuh.
3. Hanya bagian `Daftar Presensi` utama yang diubah menjadi 7 hari terakhir sampai hari ini.
4. Jangan tampilkan tanggal masa depan pada daftar utama.
5. Filter daftar utama berdasarkan:

```text
date >= today - 6 hari
date <= today
```

6. Jika bulan yang sedang dipilih bukan bulan sekarang, tetap tampilkan 7 hari relevan dalam bulan tersebut dengan aturan aman:

```text
- Untuk bulan sekarang: 7 hari terakhir sampai hari ini.
- Untuk bulan lalu/arsip: tampilkan maksimal 7 hari terakhir dalam bulan yang dipilih, atau tetap gunakan daftar bulan itu tapi batasi 7 item terbaru.
```

Rekomendasi paling sederhana:

```text
visibleDailyStatuses.take(7)
```

setelah list sudah diurutkan descending dan sudah mengecualikan libur/tanpa_data/masa depan.

7. Ubah judul dari:

```text
Daftar Presensi
```

menjadi:

```text
Daftar Presensi Terbaru
```

8. Tambahkan subtitle kecil jika rapi:

```text
Menampilkan 7 hari terakhir.
```

9. Empty state:

```text
Belum ada presensi dalam 7 hari terakhir.
```

10. Jangan mengubah logic calendar 1 bulan.
11. Jangan mengubah detail presensi.

## Acceptance criteria

- Daftar utama tidak lagi menampilkan 1 bulan penuh.
- Tanggal masa depan tidak muncul di daftar utama.
- Maksimal 7 item terbaru tampil di daftar utama.
- Ringkasan bulan tetap 1 bulan.
- Kalender 1 bulan tetap lengkap.
- Loading terasa lebih ringan secara UX.
- `flutter analyze` pass.

---

# PATCH-CLOCK-08 - Redesign tombol Clock In/Clock Out 3D Elevated + fix teks terpotong dan icon duplikat

## Masalah

Tombol Clock In/Clock Out perlu dibuat gaya 3D Elevated. Pada hasil sekarang, saat absen berhasil ada masalah:

```text
- teks subtitle terpotong: “Sudah ma...”
- icon ceklis duplikat pada Clock In completed
- Clock Out aktif masih bisa terlihat text “Clock O...” jika ruang sempit
```

## File target

```text
lib/features/home/widgets/clock_attendance_card.dart
```

## Instruksi visual

Gunakan gaya **3D / Elevated**:

```text
- rounded pill besar
- gradient hijau untuk Clock In aktif/completed
- gradient biru atau merah/oranye untuk Clock Out aktif sesuai style app
- icon lingkaran putih di kiri
- shadow bawah kuat
- highlight lembut di bagian atas
- arrow kanan jelas hanya untuk action aktif
- completed state terlihat sukses tapi tidak penuh icon berulang
```

## Instruksi logic state

Pertahankan logic:

```text
nextAction == 'masuk'  -> Clock In aktif
nextAction == 'pulang' -> Clock Out aktif
nextAction == 'done'   -> semua selesai
hasIn                  -> Clock In completed
hasOut                 -> Clock Out completed
onPressed              -> hanya aktif pada tombol nextAction
```

## Perbaikan teks terpotong

1. Jangan tampilkan subtitle panjang jika lebar tombol sempit.
2. Ganti subtitle completed:

```text
Sudah masuk -> Masuk selesai
Sudah pulang -> Pulang selesai
```

atau cukup:

```text
Selesai
```

3. Pastikan `Clock Out` tidak tampil sebagai `Clock O...` jika masih ada ruang.
4. Jika layout tetap sempit, gunakan font title lebih kecil atau gunakan label:

```text
Masuk
Pulang
```

Namun prefer tetap:

```text
Clock In
Clock Out
```

jika muat.

## Perbaikan icon ceklis duplikat

1. Jangan tampilkan dua icon ceklis pada satu tombol completed.
2. Untuk completed state pilih salah satu:

```text
- icon kiri berubah check, arrow kanan hilang/menjadi kosong
```

atau:

```text
- icon kiri tetap fingerprint, kanan check
```

Rekomendasi:

```text
Completed: icon kiri check_rounded, tombol kanan/arrow disembunyikan.
Active: icon kiri fingerprint, kanan chevron/arrow.
Disabled: icon kiri fingerprint grey, kanan chevron grey atau disembunyikan.
```

3. Jika tombol completed tidak bisa ditekan, jangan tampilkan arrow aktif.

## Acceptance criteria

- Tombol terlihat 3D Elevated dan lebih menarik.
- Tidak ada subtitle terpotong seperti “Sudah ma...”.
- Tidak ada icon ceklis duplikat pada completed state.
- Clock Out tidak terpotong jika ruang cukup.
- onPressed hanya jalan untuk tombol aktif.
- Tidak mengubah logic HomePage.
- `flutter analyze` pass.

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

## Package Check
- namespace:
- applicationId:

## Manual Build
- Tidak dijalankan oleh Codex. Build dilakukan manual oleh user.

## Notes
- Risiko tersisa:
- Hal yang perlu dicek manual:
```

Jangan menulis hasil build karena build tidak diminta.

---

# Urutan pengerjaan wajib

```text
1. Hilangkan oval kamera dan teks oval
2. Hapus warning foto kurang jelas dari UI
3. Tingkatkan kualitas kamera dengan kontrol ukuran file
4. Perbaiki overlay/status kamera
5. Relayout popup logout
6. Tambahkan alert back dari halaman utama
7. Ubah daftar presensi utama menjadi 7 hari terakhir
8. Redesign/fix tombol Clock In/Out 3D Elevated
9. flutter analyze
10. Laporan akhir
```
