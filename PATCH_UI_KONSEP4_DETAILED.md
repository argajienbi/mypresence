# PATCH_UI_KONSEP4_DETAILED.md

Repo: `argajienbi/mypresence`

Target file utama:

```text
lib/features/profile/employee_qr_page.dart
```

Tugas: redesign tampilan halaman kartu karyawan digital menggunakan konsep:

```text
CONCEPT 4: BOLD GEOMETRIC TECH
Modern. Strong. Connected.
```

Codex hanya boleh menjalankan:

```bash
flutter analyze
```

Jangan menjalankan:

```bash
flutter build apk
flutter build appbundle
flutter build aab
```

Build manual akan dilakukan user.

---

## 1. Prinsip utama

Perubahan ini hanya UI/layout.

Jangan ubah:

- service;
- model;
- Firebase path;
- payload QR/kode;
- logic flip card;
- logic capture;
- logic simpan;
- logic bagikan;
- login/session/auth;
- approval flow.

Fungsi yang tidak boleh diubah:

```dart
_loadQr
_flip
_captureCard
_saveCard
_shareCard
QrService.ensureQrToken
QrService.employeeQrPayload
Share.shareXFiles
RepaintBoundary
AnimationController
```

Kalau perlu memindahkan widget, boleh. Tapi behavior harus sama.

---

## 2. Style yang harus dipakai

Gunakan konsep:

```text
Bold Geometric Tech
```

Ciri wajib:

- modern;
- tegas;
- professional;
- tech-oriented;
- memakai bentuk diagonal;
- memakai layer geometric;
- tidak transparan/glass;
- tidak full dark premium;
- tidak minimal polos.

Jangan membuat hasil seperti:

- glassmorphism;
- kartu gelap premium penuh;
- kartu putih polos;
- nametag soft/lucu.

---

## 3. Palet warna lokal

Tambahkan konstanta lokal di `employee_qr_page.dart`:

```dart
const Color kCardDarkTeal = Color(0xFF053B40);
const Color kCardDeepTeal = Color(0xFF075E66);
const Color kCardTeal = Color(0xFF0797A5);
const Color kCardCyan = Color(0xFF12C7C9);
const Color kCardGreen = Color(0xFF56C943);
const Color kCardSoftGray = Color(0xFFF4F7F8);
const Color kCardWhite = Color(0xFFFFFFFF);
```

Warna dominan:

- header depan: `kCardDarkTeal` ke `kCardDeepTeal`;
- aksen diagonal: `kCardTeal`, `kCardCyan`, `kCardGreen`;
- area utama: putih;
- badge aktif: hijau;
- teks utama: dark teal;
- teks sekunder: muted dari theme/app yang sudah ada.

---

## 4. Struktur halaman tetap

Tetap gunakan struktur page yang sudah ada.

Halaman tetap dari:

```text
Profil > ID / QR Karyawan
```

Tetap ada:

- tombol close;
- animasi flip;
- tombol Simpan;
- tombol Bagikan;
- teks bantuan tap kartu.

Ubah subtitle halaman menjadi:

```text
Kartu identitas digital karyawan
```

Teks bantuan tetap:

```text
Tap kartu untuk melihat sisi depan/belakang.
```

---

## 5. Ukuran kartu

Ukuran ideal:

```text
width: 310
height: 520
radius: 32
```

Untuk layar kecil, boleh responsive:

```dart
final cardWidth = math.min(MediaQuery.of(context).size.width - 72, 310.0);
```

Jika card responsive, tinggi boleh proporsional:

```dart
final cardHeight = cardWidth * 1.67;
```

Jika tidak responsive, pakai fixed:

```dart
width: 310
height: 520
```

Shadow:

- blur sekitar 24-30;
- offset sekitar `Offset(0, 14)`;
- opacity hitam sekitar `.16 - .22`.

---

## 6. Layout sisi depan

Sisi depan harus mengikuti struktur ini:

```text
┌──────────────────────────────┐
│ DARK TEAL GEOMETRIC HEADER   │
│          MP LOGO             │
│      NAMA PERUSAHAAN         │
│  diagonal teal/cyan/green    │
│                              │
│       FOTO BULAT BESAR       │
│                              │
│          NAMA USER           │
│          NOMOR USER          │
│        [✓ ACTIVE]            │
│                              │
│   GEOMETRIC FOOTER           │
│   PROFESSIONAL IDENTITY      │
└──────────────────────────────┘
```

Urutan elemen depan:

1. Background putih.
2. Header dark teal pada bagian atas, tinggi sekitar `200 - 220`.
3. Logo `MP` di bagian atas tengah:
   - bentuk lingkaran putih;
   - ukuran sekitar `64 - 70`;
   - teks `MP`;
   - warna teks dark teal atau kombinasi teal/hijau.
4. Nama perusahaan:
   - uppercase;
   - center;
   - putih;
   - maksimal satu baris;
   - fallback `MYPRESENCE`.
5. Aksen diagonal:
   - minimal 3 layer diagonal;
   - warna teal, cyan, hijau;
   - posisinya melewati area header menuju area foto.
6. Foto karyawan:
   - bentuk lingkaran;
   - diameter sekitar `145 - 155`;
   - border putih;
   - shadow;
   - fallback initial jika foto kosong/gagal.
7. Nama karyawan:
   - uppercase;
   - font besar sekitar `26 - 30`;
   - tebal;
   - warna dark teal;
   - center.
8. Divider kecil tech:
   - garis kiri kanan;
   - titik/dash kecil di tengah;
   - warna teal.
9. Nomor karyawan/NIP:
   - center;
   - font sekitar `17 - 19`;
   - tebal.
10. Badge ACTIVE:
   - pill hijau;
   - ikon check;
   - teks `ACTIVE`;
   - tinggi sekitar `42 - 46`.
11. Footer geometric:
   - dark teal/teal/hijau;
   - diagonal/layered;
   - label kecil `PROFESSIONAL IDENTITY`.

Data depan yang wajib tampil:

- logo app;
- nama perusahaan;
- foto karyawan;
- nama karyawan;
- nomor karyawan/NIP;
- badge ACTIVE.

---

## 7. Layout sisi belakang

Sisi belakang harus mengikuti struktur ini:

```text
┌──────────────────────────────┐
│ DARK TEAL GEOMETRIC HEADER   │
│      NAMA PERUSAHAAN         │
│ TOGETHER. INNOVATE. GROW.    │
│                              │
│      QR / KODE BESAR         │
│                              │
│       SCAN TO VERIFY         │
│ This ID is the property ...  │
│                              │
│ GEOMETRIC FOOTER             │
│ SECURE & VERIFIABLE          │
└──────────────────────────────┘
```

Urutan elemen belakang:

1. Background putih atau soft gray.
2. Header atas dark teal:
   - tinggi sekitar `90 - 110`;
   - ada aksen corner slash/diagonal warna teal/cyan.
3. Nama perusahaan:
   - uppercase;
   - center;
   - warna dark teal atau putih sesuai area;
   - fallback `MYPRESENCE`.
4. Slogan:
   ```text
   TOGETHER. INNOVATE. GROW.
   ```
5. QR/kode besar:
   - ukuran sekitar `200 - 220`;
   - berada di tengah;
   - dalam container putih;
   - rounded sekitar `22`;
   - border halus;
   - shadow.
6. Teks:
   ```text
   SCAN TO VERIFY
   ```
   - uppercase;
   - teal;
   - tebal.
7. Teks kepemilikan:
   ```text
   This ID is the property of
   [NAMA PERUSAHAAN].
   ```
8. Footer geometric:
   - teal/hijau/dark teal;
   - label kecil:
   ```text
   SECURE & VERIFIABLE
   ```

QR/kode belakang harus menjadi elemen paling dominan.

Jangan ubah data QR/kode. Hanya ubah tampilannya.

---

## 8. Komponen private yang disarankan

Boleh membuat widget private baru di file yang sama:

```dart
_EmployeeCardShell
_FrontGeometricBackground
_BackGeometricBackground
_DiagonalBar
_GeometricFooterPainter
_TrianglePatternPainter
_CornerSlashClipper
_MpLogo
_EmployeeCirclePhoto
_InitialAvatar
_TechDivider
_ActiveBadge
_FrontFooterMark
_BackFooterMark
```

Tujuan komponen:

- `_EmployeeCardShell`: container utama kartu dengan radius, shadow, clip.
- `_FrontGeometricBackground`: background depan.
- `_BackGeometricBackground`: background belakang.
- `_DiagonalBar`: aksen diagonal.
- `_GeometricFooterPainter`: footer geometric.
- `_TrianglePatternPainter`: pattern halus.
- `_MpLogo`: logo teks MP.
- `_EmployeeCirclePhoto`: foto bulat.
- `_InitialAvatar`: fallback foto.
- `_TechDivider`: divider bawah nama.
- `_ActiveBadge`: pill ACTIVE.
- `_FrontFooterMark`: label bawah depan.
- `_BackFooterMark`: label bawah belakang.

Jika widget lama tidak dipakai lagi, boleh hapus setelah aman.

---

## 9. Data fallback

Nama perusahaan:

- gunakan field session yang tersedia jika ada;
- jika tidak ada, fallback:
  ```text
  MYPRESENCE
  ```

Nama user:

- gunakan `session.displayName`;
- jika kosong, fallback `-`.

Nomor karyawan:

- gunakan `session.nip`;
- jika kosong, fallback `-`.

Foto:

- gunakan photoUrl yang sudah ada;
- jika gagal load, tampilkan initial.

Jangan menambah field model baru hanya untuk UI.

---

## 10. Tombol bawah

Tombol `Simpan` dan `Bagikan` tetap ada.

Tombol utama:

- background `kCardTeal`;
- foreground putih;
- radius 20;
- tinggi 56;
- shadow halus.

Tombol outline:

- border `kCardTeal`;
- text `kCardTeal`;
- radius 20;
- tinggi 56.

---

## 11. Loading dan spacing

Jika ada placeholder loading card, ubah tinggi ke sekitar:

```text
540
```

Jika kartu terlalu dekat header, atur `overlapTop`:

```text
126 sampai 138
```

Jangan sampai kartu menabrak tombol close.

---

## 12. Acceptance criteria

Patch dianggap benar jika:

1. `flutter analyze` tidak error.
2. Halaman dari menu Profil tetap terbuka normal.
3. Sisi depan terlihat seperti konsep Bold Geometric Tech.
4. Sisi depan menampilkan logo, nama perusahaan, foto, nama user, nomor user, ACTIVE.
5. Sisi belakang menampilkan kode besar dan teks `SCAN TO VERIFY`.
6. Tap kartu tetap flip depan/belakang.
7. Tombol Simpan tetap ada dan tidak error.
8. Tombol Bagikan tetap ada dan tidak error.
9. Tidak ada perubahan service.
10. Tidak ada perubahan path database.
11. Tidak ada perubahan payload data.
12. Tidak ada perubahan auth/session.
13. Tidak ada build APK/AAB yang dijalankan oleh Codex.

---

## 13. Perintah terakhir Codex

Codex hanya menjalankan:

```bash
flutter analyze
```

Jangan jalankan build.

User akan build manual.
