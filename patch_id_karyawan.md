# PATCH_ID_KARYAWAN.md - Redesign Profesional Halaman ID Karyawan

Instruksi ini khusus untuk repo Flutter `argajienbi/mypresence`.

## Tujuan

Redesign halaman `ID Karyawan` agar terlihat seperti **kartu identitas digital karyawan untuk aplikasi presensi profesional**, bukan sekadar nametag dekoratif.

Fokus perubahan:

- desain lebih corporate, rapi, dan tegas;
- tetap mengikuti identitas warna MYPRESENCE: hijau-teal, aqua, putih;
- kartu terlihat seperti ID resmi perusahaan;
- QR tetap tersedia untuk kebutuhan titip absen dengan validasi admin;
- tombol `Simpan` dan `Bagikan` tetap berfungsi;
- flip card depan/belakang tetap berfungsi;
- tidak mengubah service, QR payload, Firebase path, auth, atau logic approval.

Jangan mengubah fitur QR. Jangan mengubah cara token dibuat. Jangan mengubah path database. Kita sedang mendesain ulang kartu, bukan membuka portal bug lintas dimensi.

---

# File utama

```text
lib/features/profile/employee_qr_page.dart
```

File pendukung jika perlu:

```text
lib/core/app_theme.dart
lib/widgets/sticky_curve_layout.dart
```

Namun usahakan cukup di `employee_qr_page.dart`.

---

# Kondisi kode saat ini

Saat ini `EmployeeQrPage` memakai:

```dart
StickyCurvePage(
  title: 'ID Karyawan',
  subtitle: 'Tap kartu untuk membalik nametag',
  icon: Icons.badge_rounded,
  overlapTop: 132,
  trailing: SourceRoundButton(...),
  overlapChild: ... _FrontCard / _BackCard ...,
  children: [... tombol Simpan / Bagikan ...],
)
```

Kartu depan:

```dart
_FrontCard(session: widget.session, photoUrl: ...)
```

Kartu belakang:

```dart
_BackCard(session: widget.session, payload: _payload)
```

Shell kartu:

```dart
_BadgeShell(
  accent: AppColors.primary,
  watermark: 'ID',
  child: ...
)
```

Yang perlu diperbaiki:

- kartu terlalu sederhana;
- informasi kantor dan grup terlalu kecil dan kurang terstruktur;
- tidak ada pesan resmi kartu;
- tidak ada kesan secure/verified;
- kartu depan belum terasa seperti ID digital profesional;
- desain belum cukup kuat untuk digunakan perusahaan.

---

# Target desain baru

Gaya visual baru:

```text
Professional Digital Employee ID Card
```

Karakter desain:

- header halaman tetap soft dan bersih;
- kartu utama lebih besar dan premium;
- card memakai border putih, shadow halus, gradient putih-aqua;
- bagian atas kartu berisi brand `MYPRESENCE` dan status `ACTIVE`;
- foto karyawan lebih rapi dengan frame kotak rounded dan border teal;
- nama dan NIP dibuat lebih tegas;
- role badge `ADMIN` / `USER` dibuat seperti pill profesional;
- detail kantor dan grup masuk ke panel informasi;
- kartu depan boleh menampilkan QR kecil sebagai `ID VERIFIKASI`;
- kartu belakang tetap QR besar untuk scan titip absen;
- footer kartu berisi pesan resmi:
  ```text
  Kartu ini adalah identitas resmi karyawan.
  Harap digunakan dengan bijak.
  ```

---

# Bagian A - Ubah subtitle halaman

Di `EmployeeQrPage`, ubah:

```dart
subtitle: 'Tap kartu untuk membalik nametag',
```

menjadi:

```dart
subtitle: 'Kartu identitas digital karyawan',
```

Tetap tampilkan teks bantuan di bawah kartu:

```dart
Tap kartu untuk melihat sisi depan/belakang.
```

---

# Bagian B - Pass QR payload ke kartu depan

Saat ini `_FrontCard` belum menerima QR payload. Ubah pemanggilan:

```dart
_FrontCard(
  session: widget.session,
  photoUrl: widget.photoUrl ?? widget.session.photoUrl,
),
```

menjadi:

```dart
_FrontCard(
  session: widget.session,
  photoUrl: widget.photoUrl ?? widget.session.photoUrl,
  payload: _payload,
),
```

Lalu ubah class `_FrontCard`:

```dart
class _FrontCard extends StatelessWidget {
  final AppSession session;
  final String photoUrl;
  final String payload;

  const _FrontCard({
    required this.session,
    required this.photoUrl,
    required this.payload,
  });
```

Tujuannya agar kartu depan punya QR kecil `ID VERIFIKASI`, sementara kartu belakang tetap QR besar.

---

# Bagian C - Redesign `_FrontCard`

Ganti isi `build()` pada `_FrontCard` dengan desain baru berikut.

```dart
@override
Widget build(BuildContext context) {
  final initial = session.displayName.isEmpty
      ? 'MP'
      : session.displayName.trim()[0].toUpperCase();

  return _BadgeShell(
    accent: AppColors.primary,
    watermark: 'ID',
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF08B65F), Color(0xFF078FAF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .22),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.verified_user_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MYPRESENCE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Digital Employee ID',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            _StatusPill(active: true),
          ],
        ),
        const SizedBox(height: 22),
        _EmployeePortrait(
          photoUrl: photoUrl,
          initial: initial,
        ),
        const SizedBox(height: 18),
        Text(
          session.displayName.isEmpty ? '-' : session.displayName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 24,
            height: 1.05,
            letterSpacing: .3,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'NIP: ${session.nip.isEmpty ? '-' : session.nip}',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 13),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 44, height: 1, color: AppColors.primary.withValues(alpha: .30)),
            const SizedBox(width: 10),
            _Badge(text: session.position),
            const SizedBox(width: 10),
            Container(width: 44, height: 1, color: AppColors.primary.withValues(alpha: .30)),
          ],
        ),
        const SizedBox(height: 18),
        Expanded(
          child: _EmployeeInfoPanel(
            officeName: session.officeName,
            groupName: session.groupName,
            payload: payload,
          ),
        ),
        const SizedBox(height: 12),
        const _OfficialFooter(),
      ],
    ),
  );
}
```

---

# Bagian D - Tambahkan widget pendukung

Tambahkan widget baru di bawah `_FrontCard` atau sebelum `_BackCard`.

## `_StatusPill`

```dart
class _StatusPill extends StatelessWidget {
  final bool active;

  const _StatusPill({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? AppColors.green.withValues(alpha: .12)
            : AppColors.red.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? AppColors.green.withValues(alpha: .18)
              : AppColors.red.withValues(alpha: .18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: active ? AppColors.green : AppColors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'ACTIVE' : 'INACTIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: active ? AppColors.green : AppColors.red,
            ),
          ),
        ],
      ),
    );
  }
}
```

## `_EmployeePortrait`

```dart
class _EmployeePortrait extends StatelessWidget {
  final String photoUrl;
  final String initial;

  const _EmployeePortrait({required this.photoUrl, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 154,
      height: 174,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primary.withValues(alpha: .75), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _InitialAvatar(initial: initial),
              )
            : _InitialAvatar(initial: initial),
      ),
    );
  }
}
```

## `_InitialAvatar`

```dart
class _InitialAvatar extends StatelessWidget {
  final String initial;

  const _InitialAvatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: .18),
            AppColors.blue.withValues(alpha: .12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 46,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
```

## `_EmployeeInfoPanel`

```dart
class _EmployeeInfoPanel extends StatelessWidget {
  final String officeName;
  final String groupName;
  final String payload;

  const _EmployeeInfoPanel({
    required this.officeName,
    required this.groupName,
    required this.payload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .60),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _InfoLine(
                  icon: Icons.business_rounded,
                  title: 'Kantor',
                  value: officeName.isEmpty ? '-' : officeName,
                ),
                Divider(height: 18, color: AppColors.line.withValues(alpha: .9)),
                _InfoLine(
                  icon: Icons.groups_rounded,
                  title: 'Grup',
                  value: groupName.isEmpty ? '-' : groupName,
                ),
              ],
            ),
          ),
          Container(width: 1, height: 92, color: AppColors.primary.withValues(alpha: .14)),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: .18)),
                  ),
                  child: payload.isEmpty
                      ? const SizedBox(
                          width: 62,
                          height: 62,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : QrImageView(
                          data: payload,
                          size: 72,
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.white,
                        ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'ID VERIFIKASI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## `_InfoLine`

```dart
class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoLine({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

## `_OfficialFooter`

```dart
class _OfficialFooter extends StatelessWidget {
  const _OfficialFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF078FAF), Color(0xFF08A66A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_rounded, color: Colors.white, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kartu ini adalah identitas resmi karyawan.\nHarap digunakan dengan bijak.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

# Bagian E - Redesign `_BadgeShell`

Ganti ukuran kartu dari:

```dart
width: 280,
height: 450,
```

menjadi:

```dart
width: 310,
height: 520,
```

Ganti isi `_BadgeShell.build()` menjadi versi ini:

```dart
@override
Widget build(BuildContext context) {
  return SizedBox(
    width: 310,
    height: 520,
    child: LayeredCurveCard(
      radius: 38,
      padding: EdgeInsets.zero,
      layerColor: accent.withValues(alpha: .22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Color(0xFFF7FEFF),
                    Color(0xFFEAF9FB),
                  ],
                ).asBoxDecoration(),
              ),
            ),
            Positioned(
              right: -42,
              top: -34,
              child: _Circle(size: 150, color: accent.withValues(alpha: .085)),
            ),
            Positioned(
              left: -42,
              bottom: 78,
              child: _Circle(size: 128, color: accent.withValues(alpha: .065)),
            ),
            Positioned(
              right: 18,
              bottom: 84,
              child: Icon(
                Icons.verified_user_outlined,
                size: 108,
                color: accent.withValues(alpha: .045),
              ),
            ),
            Positioned(
              right: 28,
              bottom: 116,
              child: Text(
                watermark,
                style: TextStyle(
                  fontSize: 66,
                  fontWeight: FontWeight.w900,
                  color: accent.withValues(alpha: .05),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SecurityPatternPainter(color: accent.withValues(alpha: .045)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: child,
            ),
          ],
        ),
      ),
    ),
  );
}
```

Tambahkan painter:

```dart
class _SecurityPatternPainter extends CustomPainter {
  final Color color;

  const _SecurityPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;

    for (double y = 24; y < size.height; y += 14) {
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 24) {
        path.quadraticBezierTo(x + 8, y - 8, x + 24, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SecurityPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
```

---

# Bagian F - Redesign `_BackCard`

Back card tetap QR besar, tetapi tampil lebih profesional.

Ganti isi `_BackCard.build()` menjadi:

```dart
@override
Widget build(BuildContext context) {
  return _BadgeShell(
    accent: AppColors.blue,
    watermark: 'QR',
    child: Column(
      children: [
        const Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QR KARYAWAN',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Kode verifikasi presensi',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.primary.withValues(alpha: .15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .10),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: QrImageView(
            data: payload,
            size: 220,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          session.displayName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'NIP: ${session.nip.isEmpty ? '-' : session.nip}',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.orange.withValues(alpha: .16)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_rounded, color: AppColors.orange, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'QR digunakan jika karyawan perlu dibantu absen oleh petugas/admin dan tetap membutuhkan validasi.',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

---

# Bagian G - Sesuaikan tinggi loading dan overlap

Karena kartu baru lebih tinggi, ubah loading placeholder:

```dart
height: 430,
```

menjadi:

```dart
height: 540,
```

Ubah `overlapTop` jika kartu terlalu dekat header:

```dart
overlapTop: 126,
```

Jika terlihat terlalu naik, gunakan:

```dart
overlapTop: 138,
```

Target visual: kartu masuk elegan di bawah header, tidak menabrak ikon close.

---

# Bagian H - Update tombol bawah agar lebih premium

Tombol sekarang sudah cukup, tetapi buat lebih konsisten dengan desain baru.

Ubah style `ElevatedButton.icon`:

```dart
style: ElevatedButton.styleFrom(
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
  elevation: 8,
  shadowColor: AppColors.primary.withValues(alpha: .25),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  minimumSize: const Size.fromHeight(56),
),
```

Ubah style `OutlinedButton.icon`:

```dart
style: OutlinedButton.styleFrom(
  foregroundColor: AppColors.primary,
  side: BorderSide(color: AppColors.primary.withValues(alpha: .85), width: 1.4),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  minimumSize: const Size.fromHeight(56),
),
```

---

# Bagian I - Hal yang tidak boleh diubah

Jangan ubah:

```dart
QrService.ensureQrToken
QrService.employeeQrPayload
_loadQr
_flip
_captureCard
_saveCard
Share.shareXFiles
RepaintBoundary
AnimationController
```

Jangan ubah path file hasil save kecuali ada bug jelas.

Jangan ubah teks QR payload.

Jangan ubah rule `Tap kartu untuk melihat sisi depan/belakang.`

---

# Bagian J - Acceptance criteria

Patch dianggap benar jika:

1. `flutter analyze` tidak error.
2. `flutter build apk --debug` berhasil.
3. Halaman `Profil > ID / QR Karyawan` terbuka normal.
4. Kartu depan terlihat seperti ID digital profesional.
5. Kartu depan menampilkan:
   - MYPRESENCE
   - status ACTIVE
   - foto/initial karyawan
   - nama
   - NIP
   - role badge
   - kantor
   - grup
   - QR kecil ID VERIFIKASI
   - footer resmi kartu
6. Kartu belakang tetap menampilkan QR besar.
7. Tap kartu tetap flip depan/belakang.
8. Tombol `Simpan` tetap menyimpan gambar kartu sesuai sisi yang sedang tampil.
9. Tombol `Bagikan` tetap membagikan gambar kartu.
10. Foto gagal load tidak membuat halaman error, fallback ke initial.
11. Tidak ada perubahan Firebase path.
12. Tidak ada perubahan QR payload.
13. Tidak ada perubahan service.

---

# Bagian K - Test manual

## Test tampilan depan

1. Buka aplikasi.
2. Masuk ke `Profil`.
3. Tap `ID / QR Karyawan`.
4. Pastikan kartu depan terlihat lebih profesional.
5. Pastikan foto muncul.
6. Jika foto kosong/gagal, initial tetap muncul.

## Test flip

1. Tap kartu.
2. Pastikan kartu berputar ke sisi belakang.
3. Pastikan QR besar tampil.
4. Tap lagi.
5. Pastikan kembali ke sisi depan.

## Test simpan

1. Saat sisi depan tampil, tap `Simpan`.
2. Pastikan toast sukses.
3. Tap kartu ke sisi belakang.
4. Tap `Simpan`.
5. Pastikan file belakang QR tersimpan.

## Test bagikan

1. Tap `Bagikan`.
2. Pastikan share sheet muncul.
3. Pastikan file yang dibagikan sesuai sisi kartu aktif.

---

## Catatan desain

Desain ini sengaja menaruh QR kecil di depan dan QR besar di belakang.

Alasannya:

- sisi depan terlihat seperti kartu identitas resmi;
- QR kecil memberi kesan secure/verified;
- sisi belakang tetap fokus untuk scan QR;
- fungsi titip absen tetap jelas dan tidak mencampur terlalu banyak elemen di depan.

Jangan membuat semua informasi berdesakan di kartu depan. Desain profesional itu bukan lomba memasukkan seluruh database ke satu kotak kecil. Itu namanya struk minimarket.
