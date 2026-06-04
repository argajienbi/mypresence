# Skema UI Terbaru Halaman Notifikasi MyPresence

Dokumen ini menyimpan keputusan final UI terbaru untuk halaman notifikasi yang dibuka dari ikon lonceng header.

Status: skema UI disetujui, belum implementasi kode.

---

## 1. Keputusan Final

```text
[FIX] Gunakan skema UI terbaru.
[FIX] Halaman notifikasi terpisah dari pengumuman.
[FIX] Pengumuman tetap berada di HomeAnnouncementCard.
[FIX] Halaman notifikasi hanya untuk notifikasi personal.
[FIX] Halaman notifikasi memiliki list dan detail notifikasi.
```

Alur utama:

```text
Klik Lonceng Header
→ NotificationsPage
→ Pilih salah satu notifikasi
→ Tandai sudah dibaca
→ NotificationDetailPage
```

Pengumuman tidak masuk alur ini.

---

## 2. Struktur Halaman Notifikasi

```text
NotificationsPage
├── Status bar
├── Header
│   ├── Back button
│   ├── Title: Notifikasi
│   └── Filter/settings button opsional
│
├── Search Bar
│   └── Placeholder: Cari notifikasi...
│
├── Summary Card
│   ├── Icon lonceng
│   ├── Text: 3 belum dibaca
│   ├── Subtext: Notifikasi personal Anda
│   └── Button: Tandai semua dibaca
│
├── Filter Chips
│   ├── Semua + count
│   ├── Belum dibaca + count
│   └── Kategori dropdown
│
├── Section Hari ini
│   ├── NotificationTile approval
│   ├── NotificationTile jadwal
│   └── NotificationTile koreksi
│
├── Section Sebelumnya
│   ├── NotificationTile approval lembur
│   └── NotificationTile presensi QR
│
└── Bottom navigation opsional
    ├── Beranda
    ├── Riwayat
    ├── Notifikasi
    └── Profil
```

Catatan:

```text
Bottom navigation pada halaman notifikasi opsional.
Jika halaman notifikasi dibuka sebagai child page dari Home, bottom navigation boleh tidak digunakan.
Jika ingin akses cepat seperti skema UI terbaru, bottom navigation boleh dipakai dengan tab Notifikasi aktif.
```

---

## 3. Struktur Detail Notifikasi

```text
NotificationDetailPage
├── Status bar
├── Header
│   ├── Back button
│   └── More menu opsional
│
├── Hero Icon
│   └── Icon besar sesuai kategori/status
│
├── Category Badge
│   └── APPROVAL / JADWAL / KOREKSI / PRESENSI / SISTEM
│
├── Title
│   └── Contoh: Pengajuan Cuti Disetujui
│
├── Date Time
│   └── Contoh: 05 Juni 2026, 09:30
│
├── Message Card
│   └── Isi pesan notifikasi lengkap
│
├── Detail Card
│   ├── Jenis pengajuan
│   ├── Tanggal
│   ├── Total hari
│   ├── Alasan
│   ├── Diajukan pada
│   ├── Disetujui oleh
│   └── Status
│
├── Info Card
│   └── Informasi tambahan / instruksi user
│
└── CTA Button
    └── Lihat Detail Pengajuan / Lihat Jadwal / Lihat Detail Presensi
```

---

## 4. Kategori dan Warna

| Kategori | Icon | Warna |
|---|---|---|
| Approval | `Icons.check_circle_rounded` | Hijau |
| Izin / Cuti / Sakit | `Icons.description_rounded` | Merah muda / coral |
| Jadwal | `Icons.calendar_month_rounded` | Biru |
| Lembur | `Icons.schedule_rounded` | Orange |
| Koreksi | `Icons.edit_note_rounded` | Orange |
| Presensi / QR | `Icons.qr_code_2_rounded` atau `Icons.fact_check_rounded` | Ungu / teal |
| Sistem | `Icons.settings_rounded` | Abu-abu |

---

## 5. Isi Notifikasi Personal

Halaman notifikasi hanya menampilkan:

```text
- Approval Izin
- Approval Sakit
- Approval Cuti
- Approval Lembur
- Approval Koreksi
- Perubahan Jadwal User
- Status Presensi QR
- Status Presensi Koreksi
- Status Pengajuan User
- Notifikasi Sistem Personal
```

Tidak menampilkan:

```text
- Pengumuman perusahaan
- Event kantor
- Kebijakan umum
- Berita internal
- Informasi umum perusahaan
```

---

## 6. Komponen UI yang Direncanakan

File existing yang diubah:

```text
lib/features/notifications/notifications_page.dart
lib/features/notifications/notification_detail_page.dart
lib/services/app_notification_service.dart
lib/features/home/home_page.dart
```

File baru opsional untuk merapikan struktur:

```text
lib/features/notifications/widgets/notification_search_bar.dart
lib/features/notifications/widgets/notification_summary_card.dart
lib/features/notifications/widgets/notification_filter_chips.dart
lib/features/notifications/widgets/personal_notification_tile.dart
lib/features/notifications/widgets/notification_category_icon.dart
lib/features/notifications/widgets/notification_detail_hero.dart
lib/features/notifications/widgets/notification_detail_info_card.dart
```

---

## 7. Behavior Halaman Notifikasi

### 7.1 Saat Membuka Halaman

```text
- Ambil data dari Firestore inbox dan RTDB fallback.
- Merge data.
- Filter hanya personal notification.
- Hitung unread personal.
- Tampilkan summary card.
```

### 7.2 Saat Klik Item

```text
- Tandai item sebagai read.
- Badge lonceng berkurang.
- Buka NotificationDetailPage.
```

### 7.3 Saat Klik Tandai Semua Dibaca

```text
- Tandai semua personal notification yang unread menjadi read.
- Jangan memproses pengumuman.
- Jangan mengubah AnnouncementService.
```

### 7.4 Saat Search

```text
- Search berdasarkan title, body, displayType, displaySender.
- Search hanya pada personal notification.
```

### 7.5 Saat Filter Kategori

Kategori filter awal:

```text
Semua
Belum dibaca
Approval
Jadwal
Koreksi
Presensi
Sistem
```

---

## 8. Empty State

Jika tidak ada notifikasi:

```text
Belum ada notifikasi
Approval, perubahan jadwal, dan status pengajuan akan muncul di sini.
```

Jika filter belum dibaca kosong:

```text
Tidak ada notifikasi belum dibaca
Semua notifikasi personal Anda sudah dibaca.
```

Jika search kosong:

```text
Notifikasi tidak ditemukan
Coba gunakan kata kunci lain.
```

---

## 9. Validasi Implementasi

```text
[ ] Halaman notifikasi memakai UI terbaru
[ ] Ada search bar
[ ] Ada summary unread card
[ ] Ada tombol Tandai semua dibaca
[ ] Ada filter chips
[ ] Ada section Hari ini dan Sebelumnya
[ ] Tile unread memiliki dot unread
[ ] Tile read tidak memiliki dot unread
[ ] Klik item membuka detail notifikasi
[ ] Detail notifikasi memiliki hero icon
[ ] Detail notifikasi memiliki detail card
[ ] Detail notifikasi memiliki CTA button
[ ] Pengumuman tidak muncul di halaman notifikasi
[ ] Badge lonceng hanya menghitung personal unread
[ ] HomeAnnouncementCard tetap terpisah
```
