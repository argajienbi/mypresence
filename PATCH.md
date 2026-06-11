# PATCH.md - MYPRESENCE Focused Home/Profile Polish

Dokumen ini adalah instruksi kerja untuk Codex pada repo `argajienbi/mypresence`.

Fokus patch ini hanya sisa catatan perubahan terbaru. Poin 1-7 dari patch sebelumnya sudah dianggap selesai dan **jangan disentuh lagi** kecuali ada error compile langsung.

Fokus perubahan sekarang:

```text
1. Redesign tombol absen menjadi single dynamic attendance card compact.
2. Foto profil di Home harus langsung update setelah ganti foto dari kamera/galeri.
3. Behavior tombol back: dari Riwayat/Profile kembali ke Home, popup keluar hanya saat back dari Home.
4. Card Maps/Lokasi & Radius Absensi bisa diklik dan preview maps dibuat lebih wide/tidak terasa terpotong.
```

Jangan mengerjakan fitur lain. Jangan refactor besar. Jangan mengubah package, Firebase config, struktur RTDB, schedule resolver, kamera absen, history 7 hari, popup logout, atau upload foto yang sudah selesai. Kita sedang merapikan sisa UX, bukan membuka festival bug baru.

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
AttendanceService submit path
ScheduleService logic utama
LeaveService
QR approval/request logic
CameraPresencePage behavior yang sudah diperbaiki
ProxyQrCameraPage behavior yang sudah diperbaiki
HistoryPage logic 7 hari yang sudah diperbaiki
PhotoQualityService compress/resize yang sudah berjalan
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

# PATCH-01 - Single Dynamic Attendance Card Compact

## Masalah

Tombol absen saat ini masih memakai dua tombol berdampingan `Clock In` dan `Clock Out`. Hasil 3D/elevated sebelumnya belum sesuai, ada teks terpotong dan icon kurang cocok.

Aplikasi ini memakai selfie camera, bukan fingerprint. Jadi jangan gunakan icon fingerprint sebagai icon utama.

## File target utama

```text
lib/features/home/widgets/clock_attendance_card.dart
```

Boleh ubah `home_page.dart` hanya jika perlu mengirim jam masuk/jam pulang ke widget. Jangan ubah logic `_openAttendance()`.

## Target desain

Ubah menjadi **satu card absen dinamis** yang compact dan tidak terlalu besar.

Bukan lagi:

```text
[Clock In] [Clock Out]
```

Menjadi:

```text
[ Single Dynamic Attendance Card ]
```

Ukuran card jangan terlalu tinggi. Card harus tetap proporsional agar `Menu Cepat` tidak terdorong terlalu jauh ke bawah.

Rekomendasi ukuran:

```text
height: 112 - 128 px
borderRadius: 28 - 32
padding horizontal: 18 - 22
icon circle kiri: 58 - 66 px
arrow kanan: 38 - 44 px
```

Jangan gunakan tinggi 160-180 px karena terlalu dominan.

## Icon utama

Gunakan icon kamera/selfie, bukan fingerprint dan bukan check besar.

Icon disarankan:

```dart
Icons.camera_alt_rounded
Icons.photo_camera_front_rounded
Icons.camera_enhance_rounded
```

Jangan gunakan:

```dart
Icons.fingerprint_rounded
```

Jangan gunakan ceklis besar sebagai icon utama.

Status sudah masuk/pulang dijelaskan lewat teks, bukan icon besar.

## State dan teks

### State 1: belum absen masuk

Kondisi:

```text
nextAction == 'masuk'
hasIn == false
hasOut == false
```

Tampilan:

```text
Title: Absen Masuk
Subtitle: Tap untuk selfie presensi masuk
Info kecil: Belum absen
Icon kiri: kamera/selfie
Arrow kanan: tampil
Card: hijau gradient 3D/elevated
```

### State 2: sudah masuk, belum pulang

Kondisi:

```text
nextAction == 'pulang'
hasIn == true
hasOut == false
```

Tampilan:

```text
Title: Absen Pulang
Subtitle: Tap untuk selfie presensi pulang
Info kecil: Masuk 07:32
Icon kiri: kamera/selfie
Arrow kanan: tampil
Card: biru/cyan gradient 3D/elevated atau hijau-teal sesuai style app
```

### State 3: presensi selesai

Kondisi:

```text
nextAction == 'done'
hasIn == true
hasOut == true
```

Tampilan:

```text
Title: Presensi Selesai
Subtitle: Anda sudah absen masuk & pulang
Info kecil: Masuk 07:32 • Pulang 17:05
Icon kiri: kamera/selfie
Arrow kanan: tidak tampil
Card: hijau gradient 3D/elevated tapi non-clickable
```

Jangan tampilkan icon ceklis besar sebagai icon utama. Jika ingin tanda selesai, boleh badge kecil opsional, tetapi status utama tetap lewat teks.

## Data jam masuk/pulang

Jika `ClockAttendanceCard` belum menerima jam masuk/pulang, tambahkan parameter opsional:

```dart
final String? checkInTime;
final String? checkOutTime;
```

Lalu dari `HomePage`, kirim nilai `masuk` dan `pulang` yang sudah dihitung di build.

Jaga backward compatibility kalau memungkinkan.

## Interaction behavior

```text
nextAction == 'masuk'  -> card bisa ditekan, panggil onPressed
nextAction == 'pulang' -> card bisa ditekan, panggil onPressed
nextAction == 'done'   -> card tidak bisa ditekan, jangan panggil onPressed
```

Boleh pakai animasi ringan:

```text
AnimatedContainer untuk gradient/shape
AnimatedSwitcher untuk title/subtitle/info
Durasi 200-300ms
```

Jangan tambah package animasi baru.

## Acceptance criteria

- Area absen menjadi satu card besar dinamis, bukan dua tombol.
- Card compact, tidak terlalu tinggi.
- Icon utama kamera/selfie, bukan fingerprint.
- Tidak ada icon ceklis besar sebagai icon utama.
- Status masuk/pulang/selesai dijelaskan lewat teks.
- Jam masuk dan jam pulang tampil jelas saat tersedia.
- Tidak ada teks terpotong.
- Tidak ada icon duplikat.
- `onPressed` hanya berjalan saat nextAction masuk/pulang.
- Tidak mengubah logic absensi, geofence, jadwal, kamera, Firebase.
- `flutter analyze` pass.

---

# PATCH-02 - Foto Profil Home Langsung Update Setelah Ganti Foto

## Masalah

Setelah user mengganti foto profil dari kamera/galeri, foto di halaman Profil berubah, tetapi foto profil di Home masih kosong/lama. Foto baru muncul setelah logout/login.

Penyebab utama: Home masih memakai `AppSession` lama. Profile update hanya mengubah state lokal `_photoUrl` di ProfilePage.

## File target kemungkinan

```text
lib/features/profile/profile_page.dart
lib/features/home/main_shell.dart
lib/features/home/home_page.dart
lib/features/home/widgets/home_sticky_profile_header.dart
lib/core/models/app_session.dart
lib/services/profile_service.dart
```

## Instruksi implementasi

Implementasikan refresh session/profile setelah foto profil berhasil diupload.

Rekomendasi aman:

1. `MainShell` menyimpan session aktif sebagai state lokal, bukan hanya memakai `widget.session` langsung.
2. Tambahkan callback ke `ProfilePage`, misalnya:

```dart
final ValueChanged<AppSession>? onSessionUpdated;
```

3. Setelah foto profil berhasil diupload, fetch ulang data user/session terbaru melalui service yang sudah ada.
4. Panggil `onSessionUpdated(newSession)`.
5. `MainShell` melakukan `setState(() => _session = newSession)`.
6. `HomePage`, `HistoryPage`, dan `ProfilePage` menerima `_session` terbaru.
7. `HomeStickyProfileHeader` otomatis rebuild dengan foto terbaru.

Jika membuat AppSession baru terlalu besar, minimal update field photoUrl pada session copy. Namun jangan hardcode data penting.

## Antisipasi image cache

Jika upload foto profil memakai URL/path yang sama, Flutter `NetworkImage` bisa tetap menampilkan cache lama.

Tambahkan cache busting aman:

```text
photoUrl + '?v=$updatedAt'
```

atau gunakan key berdasarkan URL/timestamp:

```dart
key: ValueKey(photoUrl)
```

Prefer path file unik berbasis timestamp jika sudah sesuai dengan ProfileService.

## Acceptance criteria

- Setelah ganti foto dari kamera, Home langsung menampilkan foto baru tanpa logout/login.
- Setelah pilih foto dari galeri, Home langsung menampilkan foto baru tanpa logout/login.
- ProfilePage tetap menampilkan foto baru.
- Employee QR jika memakai foto profil tetap menerima foto terbaru jika relevan.
- Tidak perlu restart app.
- Tidak mengubah auth flow selain refresh session/profile.
- `flutter analyze` pass.

---

# PATCH-03 - Back Button: Riwayat/Profile Kembali ke Home, Popup Hanya dari Home

## Masalah

Saat tombol back Android ditekan dari tab Riwayat atau Profil, popup keluar aplikasi langsung muncul. User ingin perilaku default lebih natural: kembali dulu ke Home.

## File target

```text
lib/features/home/main_shell.dart
```

## Logic final

Index tab saat ini diasumsikan:

```text
0 = Riwayat
1 = Home
2 = Profil
```

Aturan:

```text
Jika user di tab Riwayat:
Back -> pindah ke Home

Jika user di tab Profil:
Back -> pindah ke Home

Jika user di tab Home:
Back -> tampilkan popup “Keluar dari Aplikasi?”
```

Jangan tampilkan popup keluar dari tab Riwayat/Profile.

## Instruksi implementasi

Ubah handler `PopScope` di `MainShell` menjadi seperti konsep berikut:

```dart
onPopInvokedWithResult: (didPop, _) {
  if (didPop) return;

  if (_index != 1) {
    setState(() => _index = 1);
    return;
  }

  unawaited(_confirmExit());
}
```

Pastikan `_confirmExit()` hanya dipanggil saat tab Home aktif.

## Acceptance criteria

- Back dari Riwayat pindah ke Home.
- Back dari Profil pindah ke Home.
- Back dari Home menampilkan popup keluar aplikasi.
- Batal pada popup tetap menutup dialog saja.
- Keluar pada popup tetap menutup aplikasi.
- Back dari child route seperti kamera/detail/form tetap berjalan normal.
- `flutter analyze` pass.

---

# PATCH-04 - Card Maps Bisa Diklik dan Preview Dibuat Lebih Wide

## Masalah

Card `Lokasi & Radius Absensi` di Home sekarang terasa kurang wide. Area maps terlihat terpotong/sempit dan card belum bisa diklik untuk melihat detail lokasi.

## File target kemungkinan

```text
lib/features/home/widgets/radius_card.dart
lib/features/home/home_page.dart
```

Jika membuat sheet baru:

```text
lib/features/home/widgets/location_detail_sheet.dart
```

## Target UX

1. Card maps di Home bisa diklik.
2. Saat diklik, tampilkan detail lokasi.
3. Preview maps di Home dibuat lebih wide/tidak terasa terpotong.
4. Detail lokasi menampilkan maps lebih besar dan info geofence lengkap.

## Opsi implementasi yang disarankan

Gunakan bottom sheet, bukan halaman baru dulu.

Tap pada card:

```text
RadiusCard -> showLocationDetailSheet(...)
```

Bottom sheet berisi:

```text
- Judul: Detail Lokasi Absensi
- Nama kantor
- Status lokasi valid/tidak valid
- Maps preview lebih besar/wide
- Radius kantor
- Jarak user ke kantor
- Latitude/longitude kantor
- Latitude/longitude user
```

Jika ada tombol tambahan, boleh tambahkan:

```text
Buka di Maps
```

Tapi jangan wajib jika butuh dependency baru. Kalau pakai URL launcher belum ada, jangan tambah dependency hanya untuk ini.

## Perbaikan visual RadiusCard

- Buat area map di card Home sedikit lebih tinggi/lebar.
- Kurangi clipping/padding yang membuat maps terasa terpotong.
- Tambahkan affordance bahwa card bisa diklik:

```text
Lihat detail
atau icon chevron kecil
```

- Tetap pertahankan informasi radius dan jarak di bawah maps.
- Jangan mengubah logic location/geofence.

## Acceptance criteria

- Card maps bisa diklik.
- Klik card membuka bottom sheet/detail lokasi.
- Maps di Home terlihat lebih wide dan tidak terlalu terpotong.
- Detail lokasi menampilkan info kantor, radius, jarak, status lokasi, koordinat kantor dan user.
- Tidak mengubah logic LocationService/geofence.
- Jika user location belum tersedia, UI tetap aman dan menampilkan placeholder.
- `flutter analyze` pass.

---

# File yang jangan disentuh kecuali terpaksa

```text
lib/features/attendance/camera_presence_page.dart
lib/features/proxy_qr/proxy_qr_camera_page.dart
lib/services/photo_quality_service.dart
lib/features/history/history_page.dart
lib/features/history/attendance_detail_sheet.dart
lib/features/requests/request_status_detail_sheet.dart
android/app/build.gradle
android/app/google-services.json
lib/firebase_options.dart
```

Poin kamera, photo quality, history 7 hari, popup logout, dan warning foto sudah selesai. Jangan dirusak. Ini bukan tantangan.

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
- Apakah poin kamera/history sebelumnya tidak disentuh:
- Risiko tersisa:
- Hal yang perlu dicek manual:
```

Jangan menulis hasil build karena build tidak diminta.

---

# Urutan pengerjaan wajib

```text
1. Ubah ClockAttendanceCard menjadi single dynamic attendance card compact.
2. Tambahkan refresh session/profile agar foto Home update setelah ganti foto.
3. Ubah behavior back button di MainShell.
4. Buat RadiusCard clickable dan tambahkan detail lokasi/maps bottom sheet.
5. flutter analyze.
6. Tulis laporan akhir.
```
