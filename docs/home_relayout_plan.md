# Rencana Pemisahan Notifikasi dan Pengumuman MyPresence

Dokumen ini menggantikan arah sebelumnya: **skema Home tetap memakai skema yang sudah ada sekarang**. Fokus pekerjaan saat ini hanya membagi antara:

1. Notifikasi personal dari ikon lonceng header.
2. Pengumuman umum yang tetap muncul di Home.

Status dokumen: rencana teknis, belum implementasi kode.

---

## 1. Keputusan Utama

```text
[FIX] Skema Home tetap memakai layout yang ada sekarang.
[FIX] Tidak ada relayout besar Home pada tahap ini.
[FIX] Tidak memindahkan RadiusCard, ClockAttendanceCard, Quick Menu, atau AnnouncementCard.
[FIX] Perubahan difokuskan pada pemisahan data dan tampilan antara notifikasi dan pengumuman.
```

Artinya, struktur Home existing tetap dipertahankan:

```text
HomePage existing
├── Header / HomeStickyProfileHeader
├── ApprovedLeaveBanner jika ada
├── RadiusCard
├── ClockAttendanceCard
├── HomeQuickMenuHorizontal
└── HomeAnnouncementCard
```

Aksi cepat tetap mengikuti keputusan terakhir:

```text
Izin | Sakit | Cuti | Lembur | QR | Jadwal | Koreksi
```

Catatan:

1. `Riwayat` tidak dimasukkan ke aksi cepat karena sudah ada di bottom navigation.
2. `Koreksi` tetap direncanakan sebagai fitur baru, tetapi bukan bagian dari pekerjaan pemisahan notifikasi tahap awal.

---

## 2. Pembagian Area Informasi

| Area | Fungsi | Sumber / Service | Lokasi Tampil |
|---|---|---|---|
| Notifikasi personal | Approval, status pengajuan, jadwal personal, koreksi, sistem personal | `AppNotificationService` | Ikon lonceng header |
| Pengumuman umum | Info perusahaan, kebijakan, event, berita kantor | `AnnouncementService` | Home, di bawah aksi cepat |

Keputusan final:

```text
Lonceng header = notifikasi personal / penting untuk user.
Home pengumuman = pengumuman umum perusahaan.
Pengumuman tidak masuk halaman lonceng.
Pengumuman tidak dihitung sebagai badge unread lonceng.
```

---

## 3. Notifikasi Lonceng Header

Halaman notifikasi dibuka saat user menekan ikon lonceng di header.

Isi yang boleh masuk halaman lonceng:

```text
- Approval Izin
- Approval Sakit
- Approval Cuti
- Approval Lembur
- Approval Koreksi
- Perubahan status pengajuan user
- Perubahan jadwal user
- Validasi presensi QR
- Validasi presensi koreksi/manual
- Status akun user
- Notifikasi sistem personal
```

Kategori `refType` / `type` yang dianggap personal:

```text
approval
leave
izin
sakit
cuti
lembur
correction
koreksi
schedule
jadwal
attendance
presensi
qr
status_update
user_status
system
```

Kategori yang harus dikeluarkan dari halaman lonceng:

```text
announcement
pengumuman
news
company_event
policy
info_umum
```

---

## 4. Pengumuman Home

Pengumuman tetap muncul di Home melalui card pengumuman yang sudah ada.

Isi pengumuman:

```text
- Pengumuman perusahaan
- Kebijakan umum
- Informasi event
- Informasi operasional kantor
- Berita internal
- Informasi untuk banyak user / group / kantor / departemen
```

Sumber data pengumuman:

```text
companies/{companyId}/announcements
```

Pengumuman tidak dibuka dari lonceng. Kalau user ingin melihat semua pengumuman, alurnya berasal dari section pengumuman di Home.

---

## 5. Skema Layout Halaman Notifikasi Lonceng

Target UI mengikuti referensi halaman notifikasi:

```text
NotificationsPage
├── Background soft blue / soft green
├── SafeArea
│
├── Header
│   ├── Back button kiri
│   └── Title tengah: Notifikasi
│
├── Filter Card Putih
│   ├── Text: "3 belum dibaca"
│   ├── Chip: Semua
│   ├── Chip: Belum dibaca
│   └── Chip: Tandai dibaca
│
└── List Notifikasi Personal
    ├── NotificationTile unread
    │   ├── Icon kategori
    │   ├── Judul
    │   ├── Isi singkat
    │   ├── Meta: kategori, pengirim, waktu
    │   ├── Dot unread
    │   └── Chevron
    │
    └── NotificationTile read
        ├── Icon kategori
        ├── Judul
        ├── Isi singkat
        ├── Meta: kategori, pengirim, waktu
        └── Chevron
```

---

## 6. State UI Halaman Notifikasi

### 6.1 Filter Semua

```text
Menampilkan semua notifikasi personal.
Tidak menampilkan pengumuman.
```

### 6.2 Filter Belum Dibaca

```text
Menampilkan hanya notifikasi personal yang belum dibaca.
Tidak menampilkan pengumuman.
```

### 6.3 Tandai Dibaca

```text
Menandai semua notifikasi personal sebagai dibaca.
Tidak mengubah status pengumuman.
```

### 6.4 Empty State

Jika tidak ada notifikasi personal:

```text
Belum ada notifikasi personal.
Approval, status pengajuan, jadwal, dan informasi sistem personal akan muncul di sini.
```

Jika filter belum dibaca kosong:

```text
Tidak ada notifikasi belum dibaca.
Semua notifikasi personal sudah dibaca.
```

---

## 7. Desain Notification Tile

### 7.1 Tile belum dibaca

```text
- Background: soft blue / soft green
- Border: primary soft
- Dot unread: aktif di kanan
- Title: bold
- Body: maksimal 2 baris
- Meta: kategori, pengirim, waktu
- Chevron: kanan
```

Contoh:

```text
[Jadwal Icon] Jadwal Kerja Diperbarui     ●  >
Ini test push detail jadwal.
Jadwal • Admin • 05/06 04:37
```

### 7.2 Tile sudah dibaca

```text
- Background: putih
- Border: soft grey
- Dot unread: tidak ada
- Title: semi-bold
- Body: maksimal 2 baris
- Meta: kategori, pengirim, waktu
- Chevron: kanan
```

---

## 8. Mapping Icon dan Warna

| Jenis | Icon | Warna |
|---|---|---|
| Approval disetujui | `Icons.check_circle_rounded` | Hijau |
| Approval ditolak | `Icons.error_rounded` | Merah |
| Pending / review | `Icons.warning_rounded` | Orange |
| Jadwal | `Icons.calendar_month_rounded` atau `Icons.notifications_rounded` | Biru / teal |
| Presensi | `Icons.fact_check_rounded` | Teal |
| QR | `Icons.qr_code_2_rounded` | Hijau |
| Koreksi | `Icons.edit_note_rounded` | Orange |
| Sistem | `Icons.notifications_rounded` | Teal |

Catatan:

```text
Icon announcement / campaign tidak dipakai di halaman lonceng.
Icon pengumuman hanya dipakai di HomeAnnouncementCard.
```

---

## 9. Rencana Perubahan Service

File utama:

```text
lib/services/app_notification_service.dart
```

Tambahkan filter:

```dart
bool isAnnouncementNotification(AppNotification item) {
  final value = '${item.type} ${item.refType}'.toLowerCase();

  return value.contains('announcement') ||
      value.contains('pengumuman') ||
      value.contains('news') ||
      value.contains('company_event') ||
      value.contains('policy') ||
      value.contains('info_umum');
}

bool isPersonalNotification(AppNotification item) {
  final value = '${item.type} ${item.refType}'.toLowerCase();

  if (isAnnouncementNotification(item)) return false;

  return value.contains('approval') ||
      value.contains('leave') ||
      value.contains('izin') ||
      value.contains('sakit') ||
      value.contains('cuti') ||
      value.contains('lembur') ||
      value.contains('correction') ||
      value.contains('koreksi') ||
      value.contains('schedule') ||
      value.contains('jadwal') ||
      value.contains('attendance') ||
      value.contains('presensi') ||
      value.contains('qr') ||
      value.contains('status_update') ||
      value.contains('user_status') ||
      value.contains('system');
}
```

Tambahkan merge personal:

```dart
List<AppNotification> mergePersonalInbox(
  List<AppNotification> firestore,
  List<AppNotification> rtdb,
) {
  return mergeInbox(firestore, rtdb)
      .where(isPersonalNotification)
      .toList();
}
```

Tambahkan unread personal count:

```dart
int unreadPersonalCount(List<AppNotification> items) {
  return items.where((item) => !item.read && isPersonalNotification(item)).length;
}
```

Tambahkan mark all personal:

```dart
Future<void> markAllPersonalAsRead(
  AppSession session,
  List<AppNotification> notifications,
) async {
  final unread = notifications
      .where((item) => !item.read && isPersonalNotification(item))
      .toList();

  for (final item in unread) {
    await markAsRead(session, item);
  }
}
```

---

## 10. Rencana Perubahan NotificationsPage

File:

```text
lib/features/notifications/notifications_page.dart
```

Sebelum:

```text
mergeInbox(firestoreItems, rtdbItems)
```

Sesudah:

```text
mergePersonalInbox(firestoreItems, rtdbItems)
```

Alur baru:

```dart
final merged = _service.mergePersonalInbox(firestoreItems, rtdbItems);
final unreadCount = merged.where((e) => !e.read).length;
final items = _showUnreadOnly
    ? merged.where((e) => !e.read).toList()
    : merged;
```

Tombol `Tandai dibaca` memakai:

```text
markAllPersonalAsRead(session, merged)
```

Bukan `markAllAsRead(session, semuaNotifikasi)`.

---

## 11. Rencana Perubahan Badge Lonceng Home

File:

```text
lib/features/home/home_page.dart
lib/features/home/widgets/home_sticky_profile_header.dart
```

Target:

```text
Badge lonceng = jumlah unread notifikasi personal saja.
```

Tidak menghitung:

```text
announcement
pengumuman
news
policy
company_event
info_umum
```

---

## 12. Rencana HomeAnnouncementCard

File:

```text
lib/features/home/widgets/home_announcement_card.dart
lib/services/announcement_service.dart
```

Keputusan:

```text
HomeAnnouncementCard tetap berada di skema Home existing.
HomeAnnouncementCard tetap memakai AnnouncementService.
Tidak digabung dengan NotificationsPage.
Tidak dihitung sebagai badge lonceng.
```

Jika nanti diperlukan halaman semua pengumuman, buat halaman terpisah:

```text
lib/features/announcements/announcements_page.dart
```

---

## 13. File yang Akan Diubah

Tahap pemisahan notifikasi dan pengumuman:

```text
lib/services/app_notification_service.dart
lib/features/notifications/notifications_page.dart
lib/features/home/home_page.dart
lib/features/home/widgets/home_sticky_profile_header.dart
```

Opsional untuk merapikan UI:

```text
lib/features/notifications/widgets/notification_filter_card.dart
lib/features/notifications/widgets/personal_notification_tile.dart
lib/features/notifications/widgets/empty_personal_notification.dart
```

Tidak diubah pada tahap ini:

```text
Struktur utama HomePage
RadiusCard
ClockAttendanceCard
HomeAnnouncementCard position
BottomNavigation
```

---

## 14. Urutan Implementasi Aman

```text
1. Tambahkan filter personal vs pengumuman di AppNotificationService.
2. Tambahkan mergePersonalInbox dan unreadPersonalCount.
3. Ubah NotificationsPage agar hanya memakai mergePersonalInbox.
4. Ubah mark all read agar hanya menandai personal notification.
5. Samakan badge lonceng Home dengan unreadPersonalCount.
6. Pastikan HomeAnnouncementCard tetap memakai AnnouncementService.
7. Test data campuran: approval + jadwal + pengumuman.
8. Pastikan pengumuman tidak muncul di lonceng.
9. Pastikan pengumuman tetap muncul di Home.
10. Baru setelah stabil, lanjut redesign visual halaman notifikasi sesuai referensi.
```

---

## 15. Checklist Validasi

```text
[ ] Skema Home existing tidak berubah
[ ] RadiusCard tetap berada sesuai posisi existing
[ ] ClockAttendanceCard tetap berada sesuai posisi existing
[ ] HomeAnnouncementCard tetap berada di Home
[ ] Pengumuman tetap muncul di Home
[ ] Pengumuman tidak muncul di NotificationsPage
[ ] Badge lonceng tidak menghitung pengumuman
[ ] Lonceng hanya menampilkan notifikasi personal
[ ] Approval izin/sakit/cuti/lembur masuk lonceng
[ ] Approval koreksi masuk lonceng setelah fitur koreksi dibuat
[ ] Perubahan jadwal personal masuk lonceng
[ ] Perubahan status pengajuan user masuk lonceng
[ ] Filter Semua hanya menampilkan personal notification
[ ] Filter Belum dibaca hanya menampilkan unread personal notification
[ ] Tandai dibaca tidak memengaruhi pengumuman
[ ] Empty state sesuai kondisi personal notification
```
