# PATCH.md - Samakan Header Riwayat & Profil Mengikuti Gaya Home

Instruksi ini khusus untuk repo Flutter `argajienbi/mypresence`.

## Tujuan

Halaman berikut harus mengikuti gaya header Home:

- `Riwayat`
- `Profil`

Target visual:

- header berada sebagai overlay/floating di atas konten;
- konten scroll di belakang/di bawah curve dengan jarak yang rapi;
- tidak muncul bidang putih/alas putih yang terlihat kaku tepat di bawah curve;
- visual tetap memakai gradient hijau-biru dan curve bawah;
- fungsi data, service, Firebase, notifikasi, QR, website perusahaan, dan navigasi tidak berubah.

Masalah saat ini:

- Home memakai struktur `Stack + Positioned header + ListView dengan padding top`.
- Riwayat dan Profil memakai `Column + StickyCurveHeader + Expanded(ListView)`.
- Akibatnya saat konten discroll ke atas, Riwayat/Profil terasa punya background putih di bawah header, sedangkan Home terasa lebih floating/transparan.

Jangan ubah logic presensi, riwayat, profil, notifikasi, QR, website perusahaan, reminder, FCM, model, service, atau Firebase path apa pun. Ini patch UI/layout saja. Mohon jangan mengundang bug baru hanya karena ingin merapikan satu curve. Begitulah biasanya tragedi dimulai.

---

## Referensi struktur saat ini

### Home

Home memakai pola overlay:

```dart
Scaffold(
  backgroundColor: AppColors.bg,
  body: Stack(
    children: [
      Positioned.fill(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 188, 18, 128),
          children: [...],
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

### Riwayat / Profil saat ini

Masih memakai pola normal:

```dart
Scaffold(
  backgroundColor: AppColors.bg,
  body: Column(
    children: [
      const StickyCurveHeader(...),
      Expanded(
        child: ListView(...),
      ),
    ],
  ),
)
```

Pola ini yang harus diganti.

---

# File yang harus diubah

```text
lib/widgets/sticky_curve_header.dart
lib/features/history/history_page.dart
lib/features/profile/profile_page.dart
```

Opsional jika ingin lebih reusable:

```text
lib/widgets/curved_header_scaffold.dart
```

---

# Bagian A - Ubah `StickyCurveHeader` agar lebih cocok sebagai overlay

## File

```text
lib/widgets/sticky_curve_header.dart
```

Saat ini `StickyCurveHeader` memakai `ClipPath + Container`. Ubah menjadi `Stack + CustomPaint`, supaya tampilannya lebih mirip Home dan lebih enak dipakai sebagai overlay.

### Tambahkan parameter

Tambahkan property:

```dart
final bool showAccent;
```

Constructor menjadi:

```dart
const StickyCurveHeader({
  super.key,
  required this.title,
  required this.subtitle,
  this.icon,
  this.trailing,
  this.extra,
  this.height = 112,
  this.showAccent = true,
});
```

### Ganti isi `build()`

Ganti isi method `build()` dengan versi ini:

```dart
@override
Widget build(BuildContext context) {
  final top = MediaQuery.of(context).padding.top;
  final totalHeight = top + height;

  return SizedBox(
    height: totalHeight,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _StickyCurveHeaderPainter(showAccent: showAccent),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .90),
                          fontSize: 14,
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (extra != null) ...[
                        const SizedBox(height: 8),
                        extra!,
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
```

### Tambahkan painter baru

Tambahkan class ini di bawah `StickyCurveHeader`:

```dart
class _StickyCurveHeaderPainter extends CustomPainter {
  final bool showAccent;

  const _StickyCurveHeaderPainter({required this.showAccent});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF08B65F), Color(0xFF078FAF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final path = Path()
      ..lineTo(0, size.height - 36)
      ..quadraticBezierTo(
        size.width * .50,
        size.height + 18,
        size.width,
        size.height - 36,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);

    if (!showAccent) return;

    final accentPaint = Paint()
      ..color = Colors.white.withValues(alpha: .06)
      ..style = PaintingStyle.fill;

    final accentPath = Path()
      ..moveTo(size.width * .42, 0)
      ..cubicTo(
        size.width * .72,
        20,
        size.width * .86,
        78,
        size.width,
        58,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(accentPath, accentPaint);
  }

  @override
  bool shouldRepaint(covariant _StickyCurveHeaderPainter oldDelegate) {
    return oldDelegate.showAccent != showAccent;
  }
}
```

### Hapus class lama

Hapus class lama jika sudah tidak dipakai:

```dart
class _StickyCurveClipper extends CustomClipper<Path> { ... }
```

Catatan:

- Warna disamakan dengan Home: `0xFF08B65F` ke `0xFF078FAF`.
- Curve bawah dibuat lebih dekat ke Home.
- `StickyCurveHeader` tetap reusable untuk halaman lain.

---

# Bagian B - Ubah Riwayat menjadi layout overlay seperti Home

## File

```text
lib/features/history/history_page.dart
```

Cari return `Scaffold` di method `build()`.

Saat ini bentuknya kurang lebih:

```dart
return Scaffold(
  backgroundColor: AppColors.bg,
  body: Column(
    children: [
      const StickyCurveHeader(...),
      Expanded(
        child: ListView(...),
      ),
    ],
  ),
);
```

Ganti menjadi pola:

```dart
return Scaffold(
  backgroundColor: AppColors.bg,
  body: Stack(
    children: [
      Positioned.fill(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 136, 18, 96),
          children: [
            _MonthFilter(
              monthLabel: AppDate.monthLabel(_month),
              onPrev: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
            ),
            const SizedBox(height: 10),
            _CalendarButton(onTap: _showCalendarSheet, month: _month),
            const SizedBox(height: 16),
            const _SectionTitle('Ringkasan Bulan Ini'),
            const SizedBox(height: 10),
            _SummaryHorizontalList(
              summary: summary,
              onTap: (key, title, color) => _showSummaryDetail(
                title,
                summary.datesByKey[key] ?? const <String>[],
                color,
              ),
            ),
            const SizedBox(height: 18),
            const _SectionTitle('Daftar Presensi Terbaru'),
            const SizedBox(height: 4),
            const _SectionNote('Menampilkan 7 hari terakhir.'),
            const SizedBox(height: 10),

            // Pindahkan semua children ListView lama ke sini tanpa mengubah logic.
          ],
        ),
      ),
      const Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: StickyCurveHeader(
          title: 'Riwayat Presensi',
          subtitle: 'Rekam jejak kehadiran dan pengajuan',
          icon: Icons.history_rounded,
          height: 108,
        ),
      ),
    ],
  ),
);
```

Penting:

- Jangan pakai `Column`.
- Jangan pakai `Expanded`.
- Semua child ListView lama tetap dipertahankan.
- Hanya pindahkan `ListView` ke `Positioned.fill`.
- Padding atas disarankan `136`.
- Jika konten masih terlalu dekat dengan curve, naikkan ke `140`.
- Jika terlalu jauh, turunkan ke `128`.

---

# Bagian C - Ubah Profil menjadi layout overlay seperti Home

## File

```text
lib/features/profile/profile_page.dart
```

Cari `Scaffold` dalam `AppLoadingOverlay`.

Saat ini bentuknya kurang lebih:

```dart
return AppLoadingOverlay(
  visible: _uploading,
  message: 'Mengunggah foto profil...',
  child: Scaffold(
    backgroundColor: AppColors.bg,
    body: Column(
      children: [
        const StickyCurveHeader(...),
        Expanded(
          child: ListView(...),
        ),
      ],
    ),
  ),
);
```

Ganti bagian `body` menjadi:

```dart
body: Stack(
  children: [
    Positioned.fill(
      child: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 136, 18, 96),
        children: [
          _ProfileIdentityCard(
            session: widget.session,
            photoUrl: _photoUrl,
            onPhotoTap: _showPhotoSource,
          ),
          const SizedBox(height: 14),
          const _NotificationPermissionBanner(),
          const SizedBox(height: 14),
          const _SectionTitle('Informasi Kerja'),
          const SizedBox(height: 7),

          // Pindahkan semua children ListView lama ke sini tanpa mengubah logic.
        ],
      ),
    ),
    const Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: StickyCurveHeader(
        title: 'Profil',
        subtitle: 'Identitas dan pengaturan akun',
        icon: Icons.person_rounded,
        height: 108,
      ),
    ),
  ],
),
```

Penting:

- Jangan mengubah `_ProfileIdentityCard`.
- Jangan menghapus `_NotificationPermissionBanner`.
- Jangan menghapus menu `Website Perusahaan`.
- Jangan mengubah upload foto.
- Jangan mengubah logout.
- Hanya ubah struktur layout `body`.

---

# Bagian D - Hindari bidang putih di bawah curve

Jika setelah perubahan masih terlihat bidang putih tepat di bawah curve, penyebabnya biasanya card pertama terlalu dekat ke header.

Gunakan padding berikut:

```dart
padding: const EdgeInsets.fromLTRB(18, 140, 18, 96),
```

Untuk Riwayat, alternatif aman:

```dart
padding: const EdgeInsets.fromLTRB(18, 136, 18, 96),
```

Untuk Profil, alternatif aman:

```dart
padding: const EdgeInsets.fromLTRB(18, 140, 18, 96),
```

Jangan membuat padding terlalu besar. Nanti header terlihat seperti mengambil jatah tanah warisan.

---

# Bagian E - Jangan ubah Home

Jangan ubah file:

```text
lib/features/home/home_page.dart
lib/features/home/widgets/home_sticky_profile_header.dart
```

Home sudah menjadi acuan desain.

---

# Bagian F - Acceptance criteria

Patch dianggap benar jika:

1. `flutter analyze` tidak error.
2. `flutter build apk --debug` berhasil.
3. Home tetap sama seperti sebelumnya.
4. Riwayat memakai `Stack + Positioned StickyCurveHeader`, bukan `Column` header biasa.
5. Profil memakai `Stack + Positioned StickyCurveHeader`, bukan `Column` header biasa.
6. Saat Riwayat discroll, tidak ada bidang putih kaku tepat di bawah curve.
7. Saat Profil discroll, tidak ada bidang putih kaku tepat di bawah curve.
8. Konten tidak tertutup header.
9. Bottom navigation tetap normal.
10. Menu Profil tetap lengkap:
    - Data Pribadi
    - ID / QR Karyawan
    - Status Pengajuan
    - Pengumuman
    - Website Perusahaan
    - Pusat Bantuan
    - Syarat & Ketentuan
    - Logout
11. Detail presensi di Riwayat tetap bisa dibuka.
12. Upload foto profil tetap jalan.
13. Tidak ada perubahan Firebase path.
14. Tidak ada perubahan service.

---

# Bagian G - Test manual

## Test Profil

1. Buka tab Profil.
2. Scroll ke atas dan bawah.
3. Pastikan header curve terasa floating seperti Home.
4. Pastikan tidak ada bidang putih kaku di bawah curve.
5. Klik `Website Perusahaan`, pastikan masih membuka halaman webview.
6. Klik `Data Pribadi`, pastikan masih membuka edit profil.
7. Test logout jika perlu.

## Test Riwayat

1. Buka tab Riwayat.
2. Scroll daftar riwayat.
3. Pastikan header curve terasa floating seperti Home.
4. Pastikan filter bulan tidak ketutup header.
5. Klik detail presensi, pastikan bottom sheet tetap muncul.
6. Klik ringkasan bulan, pastikan bottom sheet tetap muncul.

## Test Home

1. Buka Home.
2. Pastikan tampilannya tidak berubah.
3. Pastikan tombol notifikasi dan card absen tetap normal.

---

## Catatan penting

Perubahan ini murni layout. Jangan biarkan AI mengubah service, model, Firebase path, reminder, atau FCM. Kita hanya ingin header Riwayat dan Profil mengikuti rasa visual Home, bukan membuka festival refactor yang mengundang bug dari segala penjuru.
