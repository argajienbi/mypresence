# PATCH.md - Redesign Tombol Clock In / Clock Out 3D Elevated

Dokumen ini adalah instruksi khusus untuk Codex pada repo `argajienbi/mypresence`.

Fokus patch ini hanya satu: memperbarui desain tombol `Clock In` dan `Clock Out` di halaman Home menjadi gaya **3D / Elevated** seperti desain pilihan nomor 8.

Jangan mengubah logic presensi, geofence, jadwal, kamera, QR, history, profile, Firebase, package, atau struktur data. Kita sedang memperbaiki tombol, bukan membangun ulang kerajaan kecil bernama Home Page.

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
AttendanceService
ScheduleService
LocationService
CameraPresencePage
QR flow
History flow
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

# PATCH-CLOCK-BUTTON-01 - Redesign Clock In / Clock Out menjadi 3D Elevated

## File target utama

```text
lib/features/home/widgets/clock_attendance_card.dart
```

Jangan ubah file lain kecuali benar-benar perlu untuk import kecil. Prioritaskan semua perubahan tetap di file ini.

---

## Kondisi saat ini

Widget saat ini:

```text
ClockAttendanceCard
_ClockActionCard
```

Tombol masih berupa dua card horizontal sederhana:

```text
Clock In  | Clock Out
```

Dengan icon fingerprint, border tipis, shadow ringan, dan state active/completed/disabled.

Logic penting yang tidak boleh rusak:

```text
nextAction == 'masuk'  -> Clock In aktif
nextAction == 'pulang' -> Clock Out aktif
nextAction == 'done'   -> semua selesai
hasIn                  -> Clock In completed
hasOut                 -> Clock Out completed
onPressed              -> tetap hanya dipanggil ketika tombol aktif
```

---

## Target desain visual

Gunakan gaya **3D / Elevated**:

```text
- tombol lebih tebal dan premium
- rounded pill besar
- gradient hijau untuk Clock In
- gradient merah/oranye untuk Clock Out
- icon lingkaran putih di kiri
- icon fingerprint / check di dalam lingkaran
- arrow kanan putih/kontras di ujung kanan
- shadow bawah lebih kuat agar terlihat elevated
- highlight lembut di bagian atas tombol
- active button terlihat hidup
- inactive/disabled button tetap terlihat tapi lebih soft/abu-abu
- completed button terlihat sukses, bukan disabled muram
```

Arah layout tetap dua tombol berdampingan agar cocok dengan halaman Home sekarang:

```text
[ Clock In ]   [ Clock Out ]
```

Jangan mengubah posisi card Radius, Menu Cepat, Pengumuman, atau Bottom Nav.

---

## Detail desain yang diinginkan

### Clock In aktif

Gunakan visual:

```text
Background: gradient hijau emerald
Icon circle: putih dengan shadow
Icon: fingerprint atau login arrow hijau
Text: putih
Subtitle: putih opacity 0.85
Arrow: putih
Shadow: hijau gelap transparan
```

Contoh warna:

```dart
const greenStart = Color(0xFF31D87A);
const greenMid = Color(0xFF16B862);
const greenEnd = Color(0xFF078B46);
```

### Clock Out aktif

Gunakan visual:

```text
Background: gradient merah/oranye
Icon circle: putih dengan shadow
Icon: fingerprint atau logout arrow merah
Text: putih
Subtitle: putih opacity 0.85
Arrow: putih
Shadow: merah gelap transparan
```

Contoh warna:

```dart
const redStart = Color(0xFFFF6B4A);
const redMid = Color(0xFFFF3B30);
const redEnd = Color(0xFFD9261C);
```

### Completed state

Jika `completed == true`:

```text
- gunakan hijau sukses
- icon berubah check_rounded
- title tetap Clock In / Clock Out
- subtitle: Sudah masuk / Sudah pulang
- tombol tidak memanggil onTap jika bukan action aktif
- visual tetap premium, bukan pucat total
```

### Disabled / belum waktunya state

Jika tombol tidak aktif dan belum completed:

```text
- background putih/abu lembut
- text abu gelap atau slate
- icon circle abu lembut
- icon abu
- arrow abu
- shadow ringan
- jangan terlihat seperti tombol utama
```

---

## Instruksi implementasi teknis

1. Pertahankan public API widget:

```dart
class ClockAttendanceCard extends StatelessWidget {
  final String nextAction;
  final bool insideRadius;
  final bool hasIn;
  final bool hasOut;
  final VoidCallback onPressed;
}
```

2. Jangan ubah cara `HomePage` memanggil widget ini.
3. Boleh ubah internal `_ClockActionCard` sepenuhnya.
4. Gunakan `AnimatedContainer` agar state active/completed/disabled terasa halus.
5. Gunakan `InkWell` atau `GestureDetector` dengan feedback yang rapi.
6. Tambahkan efek tekan sederhana jika memungkinkan tanpa State besar. Jika butuh state, boleh ubah `_ClockActionCard` menjadi `StatefulWidget`, tetapi jangan berlebihan.
7. Tinggi tombol disarankan:

```text
96 - 104 px
```

8. Border radius:

```text
30 - 34 px
```

9. Icon circle kiri:

```text
56 - 62 px
```

10. Arrow circle kanan:

```text
34 - 42 px
```

11. Pastikan tidak overflow pada layar kecil.
12. Text `Clock Out` jangan terpotong menjadi `Clock O...` jika ruang cukup. Jika tetap sempit, gunakan font sedikit lebih kecil atau layout lebih adaptif.
13. Jangan pakai package/dependency baru.
14. Jangan pakai asset gambar baru. Gunakan icon bawaan Material.
15. Jangan mengubah function `_openAttendance()` di `home_page.dart`.
16. Jangan mengubah validasi radius/jadwal.

---

## Rekomendasi struktur internal

Boleh tambahkan helper kecil di `clock_attendance_card.dart`:

```dart
class _ClockButtonStyle {
  final List<Color> gradient;
  final Color iconColor;
  final Color shadowColor;
  final Color textColor;
  final Color subtitleColor;
}
```

Atau cukup buat method:

```dart
List<Color> _gradientColors()
Color _iconColor()
Color _textColor()
List<BoxShadow> _shadows()
```

Jangan membuat terlalu banyak abstraksi. Ini tombol, bukan framework UI nasional.

---

## Interaction behavior

### Saat Clock In aktif

```text
Clock In bisa ditekan -> panggil onPressed
Clock Out disabled -> tidak bisa ditekan
```

### Setelah Clock In berhasil

```text
Clock In completed
Clock Out aktif
```

### Setelah Clock Out berhasil

```text
Clock In completed
Clock Out completed
Keduanya tidak memanggil onPressed
```

### Jika user di luar radius / jadwal belum valid

Logic tetap di `_openAttendance()` seperti sekarang.

Tombol boleh tetap terlihat aktif sesuai `nextAction`, karena validasi final tetap dilakukan saat ditekan. Jangan pindahkan logic validasi ke UI tombol.

---

## Acceptance criteria

- Tombol Clock In / Clock Out berubah menjadi gaya 3D Elevated.
- Clock In aktif terlihat hijau premium dengan gradient dan shadow.
- Clock Out aktif terlihat merah/oranye premium dengan gradient dan shadow.
- Icon kiri berada dalam lingkaran putih/elevated.
- Arrow kanan terlihat jelas.
- Completed state tetap jelas dan tidak membingungkan.
- Disabled state tetap rapi dan tidak menarik perhatian berlebihan.
- Text tidak overflow pada layar kecil.
- `onPressed` hanya dipanggil untuk tombol yang aktif.
- Tidak ada perubahan logic absensi.
- Tidak ada perubahan Firebase/package/config.
- `flutter analyze` pass.

---

## Laporan akhir Codex

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
- Hal yang perlu dicek manual:
- Risiko tersisa:
```

Jangan menulis hasil build karena build tidak diminta.

---

## Urutan pengerjaan

```text
1. Ubah desain internal _ClockActionCard ke 3D Elevated
2. Pastikan ClockAttendanceCard API tidak berubah
3. Cek state active/completed/disabled
4. Cek text overflow Clock In / Clock Out
5. flutter analyze
6. Tulis laporan akhir
```
