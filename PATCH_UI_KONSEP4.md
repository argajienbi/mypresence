# PATCH_UI_KONSEP4.md

Repo: `argajienbi/mypresence`

Tugas: redesign tampilan screen di:

```text
lib/features/profile/employee_qr_page.dart
```

Gunakan konsep visual nomor 4:

```text
Bold Geometric Tech
Modern. Strong. Connected.
```

Codex hanya boleh menjalankan:

```bash
flutter analyze
```

Jangan menjalankan build APK atau AAB. Build manual akan dilakukan user.

---

## Arah visual

Gunakan style:

- modern;
- tegas;
- tech-oriented;
- profesional;
- geometric;
- diagonal layered shapes;
- warna dark teal, teal, cyan, green, white.

Jangan gunakan:

- glassmorphism;
- dark premium full;
- clean minimal polos;
- campuran konsep lain.

---

## Warna lokal

Tambahkan warna lokal di file UI utama:

```dart
const Color kCardDarkTeal = Color(0xFF053B40);
const Color kCardDeepTeal = Color(0xFF075E66);
const Color kCardTeal = Color(0xFF0797A5);
const Color kCardCyan = Color(0xFF12C7C9);
const Color kCardGreen = Color(0xFF56C943);
const Color kCardSoftGray = Color(0xFFF4F7F8);
```

---

## Layout sisi depan

Sisi depan harus menampilkan:

- area atas dark teal;
- logo aplikasi `MP` dalam lingkaran putih;
- nama perusahaan;
- aksen diagonal teal/cyan/green;
- foto user berbentuk lingkaran besar;
- nama user besar dan tebal;
- nomor user di bawah nama;
- badge `ACTIVE` warna hijau;
- footer geometric.

Gunakan rounded corner sekitar `32`, shadow soft, dan pola geometric halus.

---

## Layout sisi belakang

Sisi belakang harus menampilkan:

- area atas dark teal;
- nama perusahaan;
- slogan kecil `TOGETHER. INNOVATE. GROW.`;
- widget kode yang sudah ada, dibuat besar dan dominan di tengah;
- teks `SCAN TO VERIFY`;
- footer geometric teal/green.

Jangan mengubah data atau cara widget kode dibuat. Hanya ubah tampilan.

---

## Ukuran

Gunakan ukuran ideal:

```text
width: 310
height: 520
radius: 32
```

Jika layar kecil, boleh responsive.

Sesuaikan placeholder/loading ke sekitar `540`.

Atur `overlapTop` di rentang `126` sampai `138` jika perlu.

---

## Komponen yang boleh dibuat

Boleh membuat private widget baru:

- shell kartu;
- background geometric depan;
- background geometric belakang;
- diagonal bar;
- footer painter;
- pattern painter;
- logo MP;
- foto bulat;
- fallback initial;
- divider tech;
- active badge.

---

## Batasan

Jangan ubah:

- service;
- model;
- path database;
- logic flip;
- logic capture;
- logic simpan;
- logic bagikan;
- payload data;
- auth/session.

Perubahan hanya UI/layout.

---

## Acceptance criteria

1. `flutter analyze` tidak error.
2. Screen dari menu Profil tetap terbuka normal.
3. Sisi depan mengikuti style Bold Geometric Tech.
4. Sisi depan menampilkan logo, foto, nama, nomor, nama perusahaan, dan ACTIVE.
5. Sisi belakang menampilkan widget kode besar dan teks `SCAN TO VERIFY`.
6. Tap tetap membalik sisi depan/belakang.
7. Tombol simpan tetap ada.
8. Tombol bagikan tetap ada.
9. Tidak ada perubahan service.
10. Tidak ada perubahan path database.

---

## Perintah terakhir Codex

Codex hanya menjalankan:

```bash
flutter analyze
```

Jangan jalankan:

```bash
flutter build apk
flutter build appbundle
```

User akan build manual.
