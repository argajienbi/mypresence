# PATCH.md - MYPRESENCE Flutter App Follow-up Fix

Dokumen ini adalah instruksi lanjutan untuk Codex pada repo `argajienbi/mypresence` setelah audit hasil patch sebelumnya.

Peran Codex: implementer teknis Flutter app.
Peran ChatGPT: orkestrator dan reviewer.

Jangan rename package, jangan refactor besar, jangan build. Tugas kali ini fokus pada perbaikan kecil lanjutan.

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

Jangan ubah Firebase config, `google-services.json`, `firebase_options.dart`, atau package Android kecuali ada bug langsung yang terbukti.

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

# PATCH-FOLLOWUP-01 - Bersihkan file cache Kotlin yang ikut commit

## Masalah

Ada file cache/build Kotlin yang ikut masuk repo:

```text
android/.kotlin/sessions/kotlin-compiler-18433859742406679139.salive
```

File ini bukan source code dan tidak boleh ada di GitHub.

## Instruksi implementasi

1. Hapus file berikut dari repo:

```text
android/.kotlin/sessions/kotlin-compiler-18433859742406679139.salive
```

2. Tambahkan ignore rule di `.gitignore`:

```gitignore
# Kotlin / Gradle local cache
android/.kotlin/
```

3. Jangan hapus file source Android lain.
4. Jangan hapus folder `android/`.
5. Jangan menyentuh package Android.

## Acceptance criteria

- File `.salive` tidak ada lagi di repo.
- `.gitignore` berisi `android/.kotlin/`.
- `flutter analyze` pass.

---

# PATCH-FOLLOWUP-02 - Rapikan daftar History agar tidak terasa dobel

## Masalah

Patch sebelumnya sudah membuat `HistoryPage` schedule-aware dan menampilkan status harian lewat `DailyHistoryStatus`.

Namun halaman masih dapat menampilkan:

```text
Daftar Presensi -> daily statuses
Pengajuan Disetujui -> leave rows
Lembur Disetujui -> overtime rows
```

Karena izin/sakit/cuti sudah masuk ke daily status, bagian `Pengajuan Disetujui` bisa terlihat dobel. Lembur juga bisa terasa dobel jika sudah diberi indikator di status harian.

## Target UX

Daftar utama harus tetap menjadi sumber utama:

```text
Daftar Presensi = status harian real berdasarkan jadwal
```

Section tambahan boleh tetap ada, tapi harus jelas bahwa itu adalah detail/arsip, bukan status harian kedua.

## Instruksi implementasi

Pilih solusi paling aman dan minim perubahan.

### Opsi A, direkomendasikan

Pertahankan section tambahan, tapi ubah judul agar tidak membingungkan:

```text
Pengajuan Disetujui
```

menjadi:

```text
Detail Pengajuan Disetujui
```

Dan:

```text
Lembur Disetujui
```

menjadi:

```text
Detail Lembur Disetujui
```

Tambahkan subtitle kecil atau teks ringkas bila perlu:

```text
Detail ini hanya arsip pengajuan, status harian tetap terlihat di Daftar Presensi.
```

### Opsi B

Jika UI terasa terlalu ramai, hilangkan section tambahan dari tampilan utama dan biarkan summary/calendar/daily list sebagai sumber utama.

Namun jangan hapus data/service. Jangan buang fungsi `getMonthlyRequests` atau `getMonthlyApprovedOvertime`, karena masih dipakai untuk summary/calendar.

## Acceptance criteria

- User tidak melihat status yang terasa dobel/membingungkan.
- `Daftar Presensi` tetap menampilkan `ALPA`, `TELAT`, `HADIR`, `IZIN`, `SAKIT`, `CUTI`, dan `JADWAL` sesuai daily status.
- Leave multi-hari tetap muncul di daily status per tanggal.
- Summary tetap berfungsi.
- Calendar tetap berfungsi.
- `flutter analyze` pass.

---

# PATCH-FOLLOWUP-03 - Perkuat edge-case ALPA untuk hari ini dan shift lintas hari

## Masalah

Logic saat ini sudah bagus untuk mayoritas kasus:

```text
hari kerja lampau tanpa presensi/keterangan -> ALPA
hari masa depan -> JADWAL
hari ini -> ALPA jika clock in window sudah lewat
```

Namun perlu dicek ulang edge-case:

1. `checkInEnd` kosong.
2. `checkInStart` dan `checkInEnd` lintas hari.
3. Shift malam / `crossesMidnight == true`.
4. Jadwal hari ini belum masuk window, jangan alpa dulu.
5. Jadwal hari ini sudah lewat window, baru alpa.

## File target

- `lib/features/history/history_page.dart`
- `lib/services/schedule_service.dart` hanya jika memang perlu helper yang sudah ada.

## Instruksi implementasi

1. Cek method yang menentukan `ALPA` untuk tanggal hari ini, misalnya `_checkInWindowClosed`.
2. Pastikan jika `schedule.checkInEnd` kosong, fallback harus aman.

Urutan fallback yang disarankan:

```text
checkInEnd
workStart + lateToleranceMinute jika workStart ada
checkInStart jika hanya itu yang ada
```

3. Jika semua jam kosong/tidak valid, jangan otomatis `ALPA`. Return `JADWAL` atau `TANPA DATA` sesuai konteks.
4. Untuk `crossesMidnight == true`, jangan asal membandingkan menit hari yang sama.
5. Jika clock in window lintas hari, gunakan helper window yang mampu menangani:

```text
startMinute <= endMinute -> normal
startMinute > endMinute -> window melewati tengah malam
```

6. Untuk hari ini, `ALPA` hanya boleh muncul jika waktu sekarang sudah benar-benar melewati akhir window clock in.
7. Jangan ubah logic validasi absen di `ScheduleService.validateAction()` kecuali memang harus dibuat helper reusable.

## Acceptance criteria

- Tanggal masa depan tidak pernah jadi `ALPA`.
- Hari ini sebelum/jelang window absen tidak jadi `ALPA`.
- Hari ini setelah window clock in lewat bisa jadi `ALPA` jika tidak ada presensi/keterangan.
- Shift lintas hari tidak salah ditandai `ALPA` sebelum waktunya.
- Jika jam jadwal tidak lengkap, jangan tandai user sebagai `ALPA`.
- `flutter analyze` pass.

---

# PATCH-FOLLOWUP-04 - Cek ulang kamera setelah anti-spam tap

## Masalah

Patch sebelumnya menambahkan debounce, capture lock, dan camera transitioning. Perlu dicek agar UX tidak terasa macet.

## File target

- `lib/features/attendance/camera_presence_page.dart`
- `lib/features/proxy_qr/proxy_qr_camera_page.dart`
- `lib/core/error_mapper.dart`

## Instruksi implementasi

1. Pastikan tombol capture aktif lagi setelah gagal capture.
2. Pastikan tombol `Ulangi Foto` aktif setelah foto berhasil diambil.
3. Pastikan tombol upload tidak bisa ditekan dua kali saat `_submitting == true`.
4. Pastikan back button tidak menyebabkan error saat camera dispose berjalan.
5. Pastikan pesan error tetap ramah, bukan raw `CameraException`.
6. Jangan ubah UI besar-besaran. Perbaiki hanya jika ada logic yang jelas bermasalah.

## Acceptance criteria

- Tekan tombol kamera berkali-kali tidak crash.
- Setelah gagal capture, user masih bisa coba lagi.
- Setelah foto berhasil, `Ulangi Foto` dan upload bekerja normal.
- `flutter analyze` pass.

---

# PATCH-FOLLOWUP-05 - Laporan akhir Codex

Setelah selesai, tulis laporan:

```text
## Summary
- Perubahan utama:
- File yang diubah:
- File yang dihapus:

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

Jangan tulis hasil build. Jangan menjalankan build. Jangan rename package. Jangan mengubah admin_web dari repo ini.

---

## Urutan pengerjaan

Kerjakan berurutan:

```text
1. PATCH-FOLLOWUP-01 - hapus cache Kotlin dan update .gitignore
2. PATCH-FOLLOWUP-02 - rapikan potensi duplikasi History
3. PATCH-FOLLOWUP-03 - perkuat edge-case ALPA hari ini/shift lintas hari
4. PATCH-FOLLOWUP-04 - cek ulang kamera anti-spam tap
5. flutter analyze
6. tulis laporan akhir
```
