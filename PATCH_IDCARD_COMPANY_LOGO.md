# PATCH_IDCARD_COMPANY_LOGO.md

Repo: `argajienbi/mypresence`

Target: memperbaiki kekurangan desain ID Card konsep 4 dan menambahkan tempat logo perusahaan yang nanti bisa diatur dari `admin_web`.

Codex hanya boleh menjalankan:

```bash
flutter analyze
```

Jangan menjalankan build APK/AAB. User akan build manual.

---

## Tujuan

Perbaiki ID Card agar:

1. `MYPRESENCE` tetap menjadi identitas aplikasi.
2. Nama perusahaan asli tampil di kartu.
3. Logo perusahaan punya tempat khusus di kartu.
4. Jika logo perusahaan belum tersedia, fallback ke logo `MP`.
5. Format NIP lebih rapi.
6. Sisi belakang tetap fokus ke QR/kode verifikasi besar.
7. Sisi belakang menampilkan identitas kecil user.
8. Tidak mengubah payload QR, service QR, path absensi, logic flip, simpan, atau bagikan.

---

## Field RTDB yang harus dibaca

Logo perusahaan nanti akan diset dari `admin_web`, tetapi Flutter harus siap membaca field ini dari:

```text
companies/{companyId}
```

Field branding yang harus didukung:

```text
company_logo_enabled: boolean
company_logo_url: string
company_logo_path: string
company_logo_updated_at: number
```

Nama perusahaan dibaca dari node company dengan fallback berlapis:

```text
company.display_name
company.name
company.company_name
MYPRESENCE
```

Logo hanya visual. Jangan masukkan logo ke payload QR.

---

## File yang diubah

Wajib:

```text
lib/services/company_service.dart
lib/features/profile/employee_qr_page.dart
```

Rekomendasi aman: cukup ubah `CompanyService` dan `employee_qr_page.dart`. Jangan menambah field session kalau tidak wajib, supaya tidak menyentuh banyak file. Mengurangi area ledakan itu strategi, bukan kemalasan.

---

## Tambah model branding di CompanyService

File:

```text
lib/services/company_service.dart
```

Tambahkan class baru di bawah `CompanyWebsiteConfig`:

```dart
class CompanyBrandingConfig {
  final String companyName;
  final bool logoEnabled;
  final String logoUrl;
  final String logoPath;

  const CompanyBrandingConfig({
    required this.companyName,
    required this.logoEnabled,
    required this.logoUrl,
    required this.logoPath,
  });

  bool get hasLogo => logoEnabled && logoUrl.trim().isNotEmpty;
}
```

Tambahkan method di `CompanyService`:

```dart
Future<CompanyBrandingConfig> loadBrandingConfig(AppSession session) async {
  final company = await _rtdb.getMap(FirebasePaths.company(session.companyId));

  final companyName = asString(
    company?['display_name'],
    asString(
      company?['name'],
      asString(company?['company_name'], 'MYPRESENCE'),
    ),
  );

  return CompanyBrandingConfig(
    companyName: companyName.trim().isEmpty ? 'MYPRESENCE' : companyName.trim(),
    logoEnabled: company?['company_logo_enabled'] == true ||
        asString(company?['company_logo_enabled']) == 'true',
    logoUrl: asString(company?['company_logo_url']),
    logoPath: asString(company?['company_logo_path']),
  );
}
```

Jangan ubah method `loadWebsiteConfig()` yang sudah ada.

---

## Update employee_qr_page.dart

Tambahkan import:

```dart
import '../../services/company_service.dart';
```

Sesuaikan path import jika struktur file meminta.

Tambahkan state di `EmployeeQrPage` state class:

```dart
final CompanyService _companyService = CompanyService();

CompanyBrandingConfig? _branding;
bool _loadingBranding = true;
```

Pada `initState()`, setelah `_loadQr();`, panggil:

```dart
_loadBranding();
```

Tambahkan method:

```dart
Future<void> _loadBranding() async {
  try {
    final branding = await _companyService.loadBrandingConfig(widget.session);
    if (!mounted) return;
    setState(() {
      _branding = branding;
      _loadingBranding = false;
    });
  } catch (_) {
    if (!mounted) return;
    setState(() {
      _branding = const CompanyBrandingConfig(
        companyName: 'MYPRESENCE',
        logoEnabled: false,
        logoUrl: '',
        logoPath: '',
      );
      _loadingBranding = false;
    });
  }
}
```

Jika analyzer memberi warning `unused _loadingBranding`, hapus state tersebut. Jangan mempertahankan variable tidak dipakai hanya demi estetika, itu hobi buruk.

---

## Pass branding ke kartu

Kartu depan:

```dart
_FrontCard(
  session: widget.session,
  photoUrl: widget.photoUrl ?? widget.session.photoUrl,
  branding: _branding,
)
```

Kartu belakang:

```dart
_BackCard(
  session: widget.session,
  payload: _payload,
  branding: _branding,
)
```

Jika branding belum selesai load, tetap render fallback `MYPRESENCE` dan logo MP. Jangan membuat halaman blank hanya karena logo belum turun dari Firebase.

---

## Widget logo perusahaan

Tambahkan widget private:

```dart
class _CompanyLogoMark extends StatelessWidget {
  final CompanyBrandingConfig? branding;

  const _CompanyLogoMark({required this.branding});

  @override
  Widget build(BuildContext context) {
    final logoUrl = branding?.logoUrl.trim() ?? '';
    final hasLogo = branding?.hasLogo == true;

    return Container(
      width: 66,
      height: 66,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: hasLogo
            ? Image.network(
                logoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _MpLogoFallback(),
              )
            : const _MpLogoFallback(),
      ),
    );
  }
}
```

Tambahkan fallback:

```dart
class _MpLogoFallback extends StatelessWidget {
  const _MpLogoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: const Text(
        'MP',
        style: TextStyle(
          color: kCardDarkTeal,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),
    );
  }
}
```

Jika `_MpLogo` lama sudah ada, ganti pemakaiannya dengan `_CompanyLogoMark`.

---

## Perbaiki kartu depan

Di `_FrontCard`, tambahkan parameter:

```dart
final CompanyBrandingConfig? branding;
```

Constructor:

```dart
const _FrontCard({
  required this.session,
  required this.photoUrl,
  required this.branding,
});
```

Ambil nama perusahaan:

```dart
final companyName = (branding?.companyName.trim().isNotEmpty == true)
    ? branding!.companyName.trim()
    : 'MYPRESENCE';
```

Header depan harus menampilkan:

```text
[Logo perusahaan atau MP]
MYPRESENCE
Nama Perusahaan
```

Jadi:
- Logo visual utama = logo perusahaan jika ada.
- `MYPRESENCE` = nama aplikasi.
- `companyName` = nama perusahaan.

Contoh:
```text
[LOGO PT]
MYPRESENCE
PT IRFAN SUGIONO
```

Jika logo belum ada:
```text
[MP]
MYPRESENCE
PT IRFAN SUGIONO
```

Jika nama perusahaan belum ada:
```text
[MP]
MYPRESENCE
```

Jangan tampilkan `MYPRESENCE` sebagai nama perusahaan jika `companyName` tersedia.

---

## Rapikan format nomor ID / NIP

Ubah tampilan dari:

```text
NIP emp-002
```

menjadi:

```text
NIP: EMP-002
```

Implementasi:

```dart
final employeeId = session.nip.trim().isEmpty ? '-' : session.nip.trim().toUpperCase();
```

Render:

```dart
Text('NIP: $employeeId')
```

---

## Perbaiki kartu belakang

Di `_BackCard`, tambahkan parameter:

```dart
final CompanyBrandingConfig? branding;
```

Constructor:

```dart
const _BackCard({
  required this.session,
  required this.payload,
  required this.branding,
});
```

Ambil:

```dart
final companyName = (branding?.companyName.trim().isNotEmpty == true)
    ? branding!.companyName.trim()
    : 'MYPRESENCE';

final employeeId = session.nip.trim().isEmpty ? '-' : session.nip.trim().toUpperCase();
final employeeName = session.displayName.trim().isEmpty ? '-' : session.displayName.trim().toUpperCase();
```

Di bawah QR, tambahkan identitas kecil:

```text
NENEK • EMP-002
```

Rekomendasi urutan:

```text
NENEK • EMP-002
SCAN TO VERIFY
This ID is the property of
PT IRFAN SUGIONO.
```

Ubah teks kepemilikan dari:

```text
This ID is the property of MYPRESENCE.
```

menjadi:

```text
This ID is the property of
PT IRFAN SUGIONO.
```

Fallback tetap `MYPRESENCE`.

Sisi belakang tidak wajib pakai logo besar. QR harus tetap jadi fokus utama, bukan figuran yang tersingkir oleh logo.

---

## Batasan wajib

Jangan ubah:

```dart
QrService.ensureQrToken
QrService.employeeQrPayload
_loadQr
_flip
_captureCard
_saveCard
_shareCard
Share.shareXFiles
RepaintBoundary
AnimationController
```

Jangan ubah:
- Firebase path QR;
- payload QR;
- flow scan;
- approval;
- auth/session;
- save/share behavior.

Patch ini hanya:
- load branding company;
- tampilkan company name;
- tampilkan logo company jika ada;
- rapikan desain ID Card.

---

## Acceptance criteria

Patch dianggap benar jika:

1. `flutter analyze` tidak error.
2. Halaman `Profil > ID / QR Karyawan` tetap terbuka.
3. Kartu depan menampilkan:
   - logo perusahaan jika tersedia;
   - fallback MP jika logo kosong/error;
   - MYPRESENCE sebagai app name;
   - nama perusahaan;
   - foto karyawan;
   - nama karyawan;
   - `NIP: EMP-002`;
   - badge ACTIVE.
4. Kartu belakang menampilkan:
   - nama perusahaan;
   - QR besar;
   - identitas kecil `NAMA • NIP`;
   - `SCAN TO VERIFY`;
   - teks kepemilikan memakai nama perusahaan.
5. Jika field `company_logo_url` belum ada, UI tetap normal.
6. Jika logo URL rusak, fallback MP tampil.
7. Tidak ada perubahan payload QR.
8. Tidak ada perubahan service QR.
9. Tidak ada perubahan path database.
10. Codex hanya menjalankan `flutter analyze`.

---

## Perintah terakhir Codex

Codex hanya menjalankan:

```bash
flutter analyze
```

Jangan build. User akan build manual.
