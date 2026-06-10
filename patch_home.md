# patch_home.md — Rencana Redesign Layout Home `mypresence`

Target repo:

```txt
argajienbi/mypresence
```

Target halaman:

```txt
lib/features/home/home_page.dart
```

Tujuan patch:
- Meredesign layout Home sesuai skema terakhir.
- Header menjadi sticky / tidak ikut scroll.
- Header lama `MY PRESENCE` dan `Aplikasi Presensi Karyawan` dihapus.
- Header baru memakai foto profil user, greeting dinamis, tanggal, dan lonceng notifikasi.
- Card lokasi dan radius tetap dipertahankan.
- Tombol presensi diganti teks menjadi Clock In / Clock Out.
- Status dan Detail Jadwal dipindahkan ke Menu Cepat.
- Menu Cepat diubah menjadi horizontal scroll.
- Notifikasi dihapus dari Menu Cepat karena pindah ke icon lonceng header.
- Pengumuman dihapus dari Menu Cepat dan dibuat card khusus di bawah.
- Bottom Navigation tetap 3 menu: Riwayat, Home, Profil.
- Warna icon mengikuti fungsi masing-masing.
- Semua teks utama hitam, kecuali teks status/peringatan/kondisi.

---

## 1. Struktur layout akhir

Susunan Home dari atas ke bawah:

```txt
1. Header Sticky
   - Foto profil user
   - Greeting dinamis: Selamat pagi/siang/sore/malam, {nama user}
   - Tanggal hari ini
   - Icon lonceng kanan + badge notifikasi penting

2. Card Lokasi & Radius Absensi
   - Status radius
   - Map preview
   - Radius kantor
   - Jarak user

3. Card Clock In / Clock Out
   - Clock In (Masuk)
   - Clock Out (Pulang)

4. Menu Cepat horizontal
   - Status
   - Detail Jadwal
   - Izin
   - Sakit
   - Cuti
   - Lembur
   - QR

5. Card Pengumuman
   - Bisa show / hide
   - Menampilkan 1–2 pengumuman terbaru
   - Tap item masuk ke detail pengumuman

6. Bottom Navigation
   - Riwayat
   - Home
   - Profil
```

---

## 2. File yang akan dibuat

Buat file baru:

```txt
lib/features/home/widgets/home_sticky_profile_header.dart
lib/features/home/widgets/clock_attendance_card.dart
lib/features/home/widgets/home_announcement_card.dart
```

Opsional jika ingin tile menu cepat lebih rapi:

```txt
lib/features/home/widgets/home_action_tile.dart
```

---

## 3. File yang akan diubah

```txt
lib/features/home/home_page.dart
lib/features/home/widgets/quick_menu.dart
```

Opsional:

```txt
lib/features/home/main_shell.dart
```

Catatan:
- `main_shell.dart` tidak perlu diubah jika Bottom Navigation tetap sama.
- `sticky_curve_header.dart` sebaiknya jangan diubah agar tidak merusak halaman lain.

---

# 4. Header Sticky Baru

## 4.1 Target tampilan

Header baru menggantikan header lama:

```txt
MY PRESENCE
Aplikasi Presensi Karyawan
Logo perusahaan / CDM
Online
```

Menjadi:

```txt
[Foto Profil]  Selamat pagi, tes              [Lonceng + badge]
               Kamis, 4 Juni 2026
```

## 4.2 Ketentuan header

Header harus:

```txt
- Sticky / tetap di atas saat konten scroll.
- Tidak ikut scroll.
- Menggunakan gradient hijau-biru.
- Menggunakan card/header modern seperti gambar terakhir.
- Foto profil user di kiri.
- Greeting + nama user di samping foto.
- Tanggal hari ini di bawah greeting.
- Icon lonceng di kanan.
- Badge merah jika ada notifikasi penting belum dibaca.
- Semua teks utama hitam.
```

## 4.3 Fungsi lonceng header

Icon lonceng khusus untuk notifikasi penting:

```txt
- approval izin/cuti/sakit/lembur disetujui atau ditolak
- perubahan jadwal user
- notifikasi sistem penting
```

Bukan untuk pengumuman umum.

Saat lonceng ditekan:

```txt
Buka halaman NotificationsPage
```

## 4.4 Greeting dinamis

Format teks utama:

```txt
Selamat pagi, {nama user}
Selamat siang, {nama user}
Selamat sore, {nama user}
Selamat malam, {nama user}
```

Aturan waktu:

```txt
04:00 - 10:59 = Selamat pagi
11:00 - 14:59 = Selamat siang
15:00 - 17:59 = Selamat sore
18:00 - 03:59 = Selamat malam
```

Helper Dart:

```dart
String greetingByTime(DateTime now) {
  final hour = now.hour;

  if (hour >= 4 && hour < 11) {
    return 'Selamat pagi';
  }

  if (hour >= 11 && hour < 15) {
    return 'Selamat siang';
  }

  if (hour >= 15 && hour < 18) {
    return 'Selamat sore';
  }

  return 'Selamat malam';
}
```

Tanggal tetap mengikuti format Indonesia:

```txt
Kamis, 4 Juni 2026
```

Gunakan helper yang sudah ada jika tersedia:

```dart
AppDate.dayDate(DateTime.now())
```

## 4.5 Implementasi sticky

Ubah struktur `HomePage` menjadi `Stack`.

Contoh struktur:

```dart
Scaffold(
  backgroundColor: AppColors.bg,
  body: Stack(
    children: [
      Positioned.fill(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 180, 18, 96),
          children: [
            // Radius card
            // Clock card
            // Quick menu
            // Announcement card
          ],
        ),
      ),

      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: HomeStickyProfileHeader(...),
      ),
    ],
  ),
)
```

Catatan:
- Nilai `top padding` disesuaikan dengan tinggi header.
- Header harus berada di luar `ListView`.
- Konten mulai di bawah header, bukan tertutup header.

---

# 5. Card Lokasi & Radius Absensi

## 5.1 Status

Card lokasi tetap dipertahankan.

Isi:

```txt
Lokasi & Radius Absensi
Status radius
Map preview
Radius
Jarak
```

## 5.2 Fungsi

Tetap memakai logic lama:

```txt
- Ambil lokasi user.
- Hitung jarak user ke kantor.
- Tentukan apakah user di dalam radius.
- Jika di luar radius, tombol absen tetap terlihat tapi aksi ditolak dengan pesan.
```

## 5.3 Warna

```txt
Icon lokasi        = teal / biru
Di Dalam Radius    = hijau
Di Luar Radius     = oranye / merah
Radius/Jarak teks  = hitam
```

File yang kemungkinan tetap dipakai:

```txt
lib/features/home/widgets/radius_card.dart
```

---

# 6. Clock In / Clock Out Card

## 6.1 Target perubahan

Tombol lama:

```txt
Clock In
Clock Out
```

Diganti menjadi:

```txt
Clock In
(Masuk)

Clock Out
(Pulang)
```

## 6.2 Aturan status

Jika belum absen masuk:

```txt
Clock In aktif
Clock Out nonaktif
```

Jika sudah absen masuk dan belum pulang:

```txt
Clock In nonaktif
Clock Out aktif
```

Jika sudah absen masuk dan pulang:

```txt
Clock In nonaktif
Clock Out nonaktif
Tampilkan status selesai
```

Jika user di luar radius:

```txt
Tombol tetap tampil
Saat ditekan muncul pesan:
"Anda berada di luar radius kantor."
```

## 6.3 Warna

```txt
Clock In aktif   = hijau
Clock Out aktif  = biru
Nonaktif         = abu-abu
Teks utama       = hitam
Icon aktif       = warna fungsi
Icon nonaktif    = abu-abu
```

## 6.4 File baru

Buat widget baru:

```txt
lib/features/home/widgets/clock_attendance_card.dart
```

Alasan:
- Lebih aman daripada langsung mengubah `attendance_segment_button.dart`.
- Widget lama bisa tetap menjadi fallback kalau desain baru bermasalah.

## 6.5 Props widget

Widget baru minimal menerima:

```dart
class ClockAttendanceCard extends StatelessWidget {
  final String nextAction;
  final bool insideRadius;
  final bool hasIn;
  final bool hasOut;
  final VoidCallback onPressed;

  const ClockAttendanceCard({
    super.key,
    required this.nextAction,
    required this.insideRadius,
    required this.hasIn,
    required this.hasOut,
    required this.onPressed,
  });
}
```

Di `HomePage`, ganti:

```dart
AttendanceSegmentButton(...)
```

menjadi:

```dart
ClockAttendanceCard(
  nextAction: nextAction,
  insideRadius: _insideRadius,
  hasIn: hasIn,
  hasOut: hasOut,
  onPressed: _openAttendance,
)
```

---

# 7. Menu Cepat Horizontal

## 7.1 Target perubahan

Menu Cepat dari grid 2 baris menjadi horizontal scroll.

Menu yang tampil:

```txt
Status
Detail Jadwal
Izin
Sakit
Cuti
Lembur
QR
```

Menu yang dihapus:

```txt
Notifikasi
Pengumuman
```

Alasan:
- Notifikasi pindah ke icon lonceng header.
- Pengumuman pindah ke card khusus.

## 7.2 Header menu cepat

Tambahkan header section:

```txt
Menu Cepat
Akses cepat ke fitur-fitur penting yang sering digunakan.
Lihat semua >
```

## 7.3 Fungsi menu

```txt
Status
→ Jalankan _showStatusDetails(...)

Detail Jadwal
→ Jalankan _showScheduleDetails()

Izin
→ Jalankan _openLeave('izin')

Sakit
→ Jalankan _openLeave('sakit')

Cuti
→ Jalankan _openLeave('cuti')

Lembur
→ Jalankan _openLeave('lembur')

QR
→ Jalankan _openQrTeman()
```

## 7.4 Lihat semua

Untuk tahap pertama:

```txt
Lihat semua membuka bottom sheet menu lengkap
```

Jika belum siap, boleh dibuat:

```dart
onPressed: () {
  AppToast.info(context, 'Menu lengkap segera tersedia.');
}
```

## 7.5 File yang diubah

```txt
lib/features/home/widgets/quick_menu.dart
```

Atau buat widget baru:

```txt
lib/features/home/widgets/home_quick_menu_horizontal.dart
```

Rekomendasi:
- Buat widget baru agar layout lama tetap aman.

## 7.6 Warna icon menu

```txt
Status         = slate / abu gelap
Detail Jadwal = teal
Izin           = biru
Sakit          = merah
Cuti           = oranye
Lembur         = ungu
QR             = hijau / emerald
```

Teks menu:

```txt
Hitam
```

---

# 8. Card Pengumuman

## 8.1 Target tampilan

Card baru di bawah Menu Cepat:

```txt
Pengumuman                         [chevron up/down]
- Pengumuman terbaru 1
- Pengumuman terbaru 2
```

## 8.2 Sumber data

Gunakan service yang sudah ada:

```txt
AnnouncementService.watchAnnouncements(session)
```

Path data:

```txt
companies/{companyId}/announcements
```

## 8.3 Perilaku card

Jika expanded:

```txt
Tampilkan maksimal 2 pengumuman terbaru.
```

Jika collapsed:

```txt
Hanya tampil header Pengumuman.
```

Jika kosong:

```txt
Belum ada pengumuman terbaru.
```

Tap item:

```txt
Buka AnnouncementDetailPage
```

## 8.4 File baru

Buat widget:

```txt
lib/features/home/widgets/home_announcement_card.dart
```

## 8.5 Props widget

```dart
class HomeAnnouncementCard extends StatefulWidget {
  final AppSession session;

  const HomeAnnouncementCard({
    super.key,
    required this.session,
  });
}
```

## 8.6 Warna icon pengumuman

```txt
Pengumuman umum    = teal / biru
Peringatan         = oranye
Penting/danger     = merah
Sukses/info sukses = hijau
```

---

# 9. Bottom Navigation

Tetap 3 menu:

```txt
Riwayat
Home
Profil
```

File:

```txt
lib/features/home/main_shell.dart
```

Tidak perlu diubah untuk tahap ini.

---

# 10. Warna dan teks

## 10.1 Aturan teks

Semua teks utama gunakan warna hitam:

```dart
AppColors.text
```

Pengecualian:

```txt
- Status radius
- Badge
- Status aktif/nonaktif
- Warning
- Error
- Success
```

## 10.2 Aturan warna fungsi

```txt
Hijau    = aksi berhasil / Clock In / aktif
Biru     = Clock Out / informasi
Teal     = lokasi / jadwal / pengumuman
Oranye   = peringatan / di luar radius / cuti
Merah    = sakit / error / ditolak
Ungu     = lembur
Abu-abu  = nonaktif / sekunder
```

---

# 11. Tahapan implementasi

## Tahap 1 — Buat widget baru

Buat:

```txt
home_sticky_profile_header.dart
clock_attendance_card.dart
home_announcement_card.dart
home_quick_menu_horizontal.dart
```

## Tahap 2 — Update `HomePage`

Ubah layout menjadi:

```txt
Stack
- Header sticky
- ListView konten
```

Pindahkan item:

```txt
Status
Detail Jadwal
```

dari card sejajar lama ke Menu Cepat horizontal.

## Tahap 3 — Sambungkan fungsi lama

Pastikan fungsi lama tetap dipakai:

```txt
_openAttendance()
_showStatusDetails()
_showScheduleDetails()
_openLeave()
_openQrTeman()
_openNotifications()
```

Khusus `_openNotifications()` dipakai oleh icon lonceng header.

## Tahap 4 — Tambahkan Pengumuman

Pasang:

```dart
HomeAnnouncementCard(session: widget.session)
```

di bawah Menu Cepat.

## Tahap 5 — Test manual

Test wajib:

```txt
1. Home berhasil dibuka.
2. Header tetap di atas saat konten scroll.
3. Greeting berubah sesuai waktu.
4. Nama user muncul benar.
5. Tanggal hari ini muncul benar.
6. Badge notifikasi muncul jika ada unread.
7. Tap lonceng membuka NotificationsPage.
8. Radius card tetap membaca lokasi.
9. Clock In tetap menjalankan absen masuk.
10. Clock Out tetap menjalankan absen pulang.
11. Status membuka bottom sheet status.
12. Detail Jadwal membuka bottom sheet jadwal.
13. Menu Cepat bisa horizontal scroll.
14. Izin/Sakit/Cuti/Lembur membuka form sesuai tipe.
15. QR membuka halaman QR.
16. Pengumuman tampil dari RTDB.
17. Pengumuman bisa collapse/expand.
18. Tap pengumuman membuka detail.
19. Bottom navigation tetap jalan.
```

---

# 12. Commit yang disarankan

```bash
git status

git add \
lib/features/home/home_page.dart \
lib/features/home/widgets/home_sticky_profile_header.dart \
lib/features/home/widgets/clock_attendance_card.dart \
lib/features/home/widgets/home_announcement_card.dart \
lib/features/home/widgets/home_quick_menu_horizontal.dart

git commit -m "Redesign home layout with sticky profile header"

git push origin main
```

---

# 13. Risiko dan catatan

## Risiko 1 — Header menutup konten

Solusi:
- Pastikan `ListView.padding.top` lebih besar dari tinggi header.

## Risiko 2 — Badge notifikasi menghitung pengumuman

Solusi:
- Filter badge hanya untuk refType penting seperti:

```txt
approval
leave
schedule
jadwal
attendance
system
```

Jangan masukkan:

```txt
announcement
pengumuman
```

## Risiko 3 — Clock In / Clock Out rusak

Solusi:
- Jangan ubah `_openAttendance()`.
- Hanya ubah widget visual pemanggilnya.

## Risiko 4 — Quick Menu kehilangan fungsi

Solusi:
- Pastikan setiap tile menerima callback dari `HomePage`.

---

# 14. Checklist hasil akhir

```txt
[ ] Header lama MY PRESENCE hilang
[ ] Subtitle Aplikasi Presensi Karyawan hilang
[ ] Foto profil tampil di kiri
[ ] Greeting dinamis tampil
[ ] Tanggal tampil
[ ] Lonceng tampil kanan
[ ] Badge notifikasi tampil
[ ] Header sticky tidak ikut scroll
[ ] Radius card tetap
[ ] Clock In / Clock Out tampil gaya baru
[ ] Status pindah ke Menu Cepat
[ ] Detail Jadwal pindah ke Menu Cepat
[ ] Menu Cepat horizontal
[ ] Notifikasi hilang dari Menu Cepat
[ ] Pengumuman hilang dari Menu Cepat
[ ] Card Pengumuman tampil di bawah
[ ] Bottom Navigation tetap
[ ] Warna icon sesuai fungsi
[ ] Teks utama hitam
```
