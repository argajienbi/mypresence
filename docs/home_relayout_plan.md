# Rencana Relayout Home MyPresence

Dokumen ini menyimpan keputusan desain dan rencana implementasi relayout Home pada repo `argajienbi/mypresence`.

Status dokumen: rencana desain, belum implementasi kode.

---

## 1. Tujuan Relayout Home

Home diarahkan menjadi halaman utama yang lebih fokus ke kebutuhan harian user:

1. Melihat status kehadiran hari ini.
2. Melakukan Clock In / Clock Out.
3. Melihat detail jadwal hari ini.
4. Mengakses menu aksi cepat.
5. Membaca pengumuman perusahaan.
6. Membuka notifikasi penting melalui ikon lonceng di header.

Referensi visual utama: desain home dengan header hijau, kartu status kehadiran putih, aksi cepat horizontal, dan pengumuman di bawah aksi cepat.

---

## 2. Keputusan Layout Home Baru

Urutan layout Home final:

1. Header hijau.
   - Avatar user.
   - Greeting user.
   - Tanggal hari ini.
   - Icon lonceng notifikasi dengan badge unread.
2. Kartu utama presensi.
   - Status kehadiran.
   - Tombol Clock In dan Clock Out.
   - Pesan status presensi hari ini.
   - Detail jadwal hari ini.
3. Aksi cepat.
   - Izin.
   - Sakit.
   - Cuti.
   - Lembur.
   - QR.
   - Jadwal.
   - Koreksi.
4. Pengumuman.
   - Muncul langsung di Home.
   - Posisi berada di bawah menu aksi cepat.
5. Bottom navigation.
   - Riwayat.
   - Home.
   - Profil.

---

## 3. Perubahan dari Layout Lama

Layout lama menampilkan RadiusCard / peta lokasi sebelum kartu presensi. Pada layout baru, prioritas utama dipindah ke presensi dan jadwal.

Keputusan:

1. `RadiusCard` tidak menjadi konten utama paling atas.
2. Informasi lokasi tetap dipakai sebagai validasi Clock In / Clock Out.
3. Detail radius dan peta dipindahkan ke bottom sheet atau detail lokasi.
4. Logic validasi presensi tidak diubah.
5. Relayout difokuskan pada struktur UI dan pemisahan konten.

---

## 4. Kartu Utama Presensi

Widget baru yang direncanakan:

```text
lib/features/home/widgets/home_attendance_hero_card.dart
```

Isi kartu:

1. Label kecil: `Status Kehadiran`.
2. Status utama:
   - `Belum Clock In`.
   - `Sudah Clock In`.
   - `Presensi Hari Ini Selesai`.
   - `Izin Disetujui` / `Sakit Disetujui` / `Cuti Disetujui`.
3. Tombol aksi:
   - `Clock In` aktif jika user belum clock in.
   - `Clock Out` aktif jika user sudah clock in dan belum clock out.
   - Kedua tombol disabled jika presensi selesai atau user sedang izin/sakit/cuti disetujui.
4. Pesan status:
   - `Belum melakukan Clock In hari ini.`
   - `Silakan lakukan Clock Out sesuai jadwal.`
   - `Presensi hari ini sudah lengkap.`
   - `Pengajuan hari ini sudah disetujui admin.`
5. Detail jadwal hari ini:
   - Shift.
   - Jam Masuk.
   - Jam Pulang.
   - Lokasi / Kantor.
   - Status Jadwal.

Data yang digunakan tetap dari `HomePage`:

```text
_today
_schedule
_loadingSchedule
_approvedLeaveToday
hasIn
hasOut
nextAction
widget.session.officeName
widget.session.officeAddress
```

---

## 5. Aksi Cepat Final

Aksi cepat final hanya berisi 7 menu:

```text
Izin | Sakit | Cuti | Lembur | QR | Jadwal | Koreksi
```

Menu yang dihapus dari aksi cepat:

1. `Status`.
2. `Riwayat`.

Alasan:

1. Status sudah masuk ke kartu utama presensi.
2. Riwayat sudah tersedia di bottom navigation.

### 5.1 Izin

Fungsi: pengajuan izin biasa.

Isi form:

```text
- Tanggal izin
- Durasi izin
- Alasan izin
- Lampiran opsional
- Tombol Kirim Pengajuan
- Status: Menunggu / Disetujui / Ditolak
```

Action:

```text
LeaveFormPage(type: izin)
```

### 5.2 Sakit

Fungsi: pengajuan sakit.

Isi form:

```text
- Tanggal mulai sakit
- Tanggal selesai sakit
- Keterangan sakit
- Upload surat dokter / bukti sakit
- Tombol Kirim Pengajuan
- Status: Menunggu / Disetujui / Ditolak
```

Action:

```text
LeaveFormPage(type: sakit)
```

### 5.3 Cuti

Fungsi: pengajuan cuti.

Isi form:

```text
- Jenis cuti
- Tanggal mulai
- Tanggal selesai
- Total hari otomatis
- Alasan cuti
- Lampiran opsional
- Tombol Kirim Pengajuan
- Status: Menunggu / Disetujui / Ditolak
```

Action:

```text
LeaveFormPage(type: cuti)
```

### 5.4 Lembur

Fungsi: pengajuan atau laporan lembur.

Isi form:

```text
- Tanggal lembur
- Jam mulai
- Jam selesai
- Total durasi otomatis
- Lokasi lembur
- Deskripsi pekerjaan
- Lampiran opsional
- Tombol Kirim Pengajuan
- Status: Menunggu / Disetujui / Ditolak
```

Action:

```text
LeaveFormPage(type: lembur)
```

### 5.5 QR

Fungsi: presensi proxy saat user lupa membawa HP.

Isi alur:

```text
- Scan QR teman
- Validasi pemilik QR
- Ambil foto setelah QR berhasil
- Kirim presensi metode QR
- Catat siapa yang melakukan scan
- Kirim ke admin untuk validasi
```

Data wajib:

```text
- User yang diabsenkan
- User yang melakukan scan
- Waktu scan
- Lokasi scan
- Foto bukti
- Metode presensi: QR Proxy
- Status validasi admin
```

Action:

```text
ProxyAttendancePage
```

### 5.6 Jadwal

Fungsi: melihat jadwal kerja.

Isi menu:

```text
- Jadwal hari ini
- Shift aktif
- Jam masuk
- Jam pulang
- Window clock in
- Window clock out
- Lokasi kerja
- Status jadwal: Aktif / Libur / Lembur / Khusus
```

Mode yang tetap dipertahankan:

```text
- Harian
- Mingguan
- Bulanan
```

Action:

```text
HomeSchedulePreview / bottom sheet detail jadwal
```

### 5.7 Koreksi

Fitur baru. Sebelumnya belum ada dan perlu direncanakan untuk dibuat.

Fungsi: memperbaiki data presensi ketika user lupa absen atau ada data presensi bermasalah.

Kasus penggunaan:

```text
- Lupa Clock In
- Lupa Clock Out
- Salah Jam Masuk
- Salah Jam Pulang
- Lokasi Bermasalah
- Foto Bermasalah
- Aplikasi error saat absen
- Lainnya
```

Isi form:

```text
- Tanggal presensi yang dikoreksi
- Jenis koreksi
- Jam yang diajukan
- Alasan koreksi
- Lampiran bukti opsional
- Tombol Kirim Koreksi
- Status pengajuan
```

Status:

```text
pending     = Menunggu persetujuan admin
approved    = Disetujui
rejected    = Ditolak
cancelled   = Dibatalkan user
```

Rencana path data:

```text
attendance_corrections
└── correctionId
    ├── userId
    ├── companyId
    ├── userName
    ├── date
    ├── correctionType
    ├── requestedTime
    ├── reason
    ├── attachmentUrl
    ├── oldAttendanceData
    ├── status
    ├── adminNote
    ├── createdAt
    ├── updatedAt
    └── reviewedBy
```

Rencana file baru:

```text
lib/features/correction/correction_form_page.dart
lib/features/correction/correction_history_page.dart
lib/services/attendance_correction_service.dart
lib/core/models/attendance_correction.dart
```

---

## 6. Rencana Pemisahan Notifikasi dan Pengumuman

Keputusan baru: notifikasi approval dan perubahan status user harus dipisahkan dari pengumuman.

### 6.1 Notifikasi via lonceng header

Notifikasi yang muncul saat user menekan ikon lonceng di header:

1. Approval izin.
2. Approval sakit.
3. Approval cuti.
4. Approval lembur.
5. Approval koreksi presensi.
6. Perubahan status pengajuan user.
7. Perubahan jadwal user yang perlu perhatian langsung.
8. Notifikasi sistem yang bersifat personal untuk user.

Tujuan:

1. Lonceng hanya untuk informasi penting/personal.
2. Badge unread di header dihitung dari notifikasi penting/personal saja.
3. Pengumuman umum tidak menaikkan badge lonceng header.

Kategori notifikasi personal:

```text
approval
leave
izin
sakit
cuti
lembur
correction
schedule
attendance
status_update
system
```

### 6.2 Pengumuman di Home

Pengumuman tetap muncul di Home, tepat di bawah menu aksi cepat.

Isi pengumuman:

1. Pengumuman perusahaan.
2. Kebijakan umum.
3. Informasi event.
4. Informasi operasional yang berlaku untuk banyak user.
5. Berita internal kantor.

Kategori pengumuman:

```text
announcement
pengumuman
news
info_umum
company_event
policy
```

Pengumuman tidak muncul di halaman notifikasi approval/personal, kecuali nanti dibuat halaman `Semua Pengumuman` terpisah.

---

## 7. Rencana UI Halaman Notifikasi

Halaman notifikasi dibuka dari ikon lonceng di header.

Referensi visual: halaman notifikasi dengan background soft blue, kartu filter, item unread berwarna biru muda, item read berwarna putih.

Isi halaman:

1. App bar:
   - Tombol back.
   - Title `Notifikasi`.
2. Summary unread:
   - Contoh: `3 belum dibaca`.
3. Filter:
   - `Semua`.
   - `Belum dibaca`.
   - `Tandai dibaca`.
4. List notifikasi:
   - Icon kategori.
   - Judul.
   - Isi singkat.
   - Kategori.
   - Pengirim.
   - Tanggal/jam.
   - Dot unread.
   - Chevron detail.

Notifikasi unread:

```text
- Background biru muda
- Border biru muda lebih tegas
- Dot unread aktif
```

Notifikasi read:

```text
- Background putih
- Border soft grey
- Dot unread hilang
```

---

## 8. Rencana Data dan Filtering

Service notifikasi perlu memisahkan dua jenis konten:

1. Personal notifications.
2. Announcements.

Rencana method:

```text
watchPersonalInbox(session)
watchAnnouncements(session)
mergePersonalInbox(firestoreItems, rtdbItems)
markPersonalAsRead(session, item)
markAllPersonalAsRead(session)
```

Filtering personal notification:

```text
bool isPersonalNotification(String refType) {
  final value = refType.toLowerCase();
  if (value.contains('announcement') || value.contains('pengumuman')) return false;
  return value.contains('approval') ||
         value.contains('leave') ||
         value.contains('izin') ||
         value.contains('cuti') ||
         value.contains('sakit') ||
         value.contains('lembur') ||
         value.contains('correction') ||
         value.contains('koreksi') ||
         value.contains('schedule') ||
         value.contains('jadwal') ||
         value.contains('attendance') ||
         value.contains('presensi') ||
         value.contains('status_update') ||
         value.contains('system');
}
```

Filtering announcement:

```text
bool isAnnouncement(String refType) {
  final value = refType.toLowerCase();
  return value.contains('announcement') ||
         value.contains('pengumuman') ||
         value.contains('news') ||
         value.contains('policy') ||
         value.contains('company_event');
}
```

---

## 9. File yang Akan Diubah

File existing yang direncanakan berubah:

```text
lib/features/home/home_page.dart
lib/features/home/main_shell.dart
lib/features/home/widgets/home_sticky_profile_header.dart
lib/features/home/widgets/home_quick_menu_horizontal.dart
lib/features/home/widgets/home_announcement_card.dart
lib/features/notifications/notifications_page.dart
lib/services/app_notification_service.dart
lib/core/app_theme.dart
```

File baru yang direncanakan:

```text
lib/features/home/widgets/home_attendance_hero_card.dart
lib/features/home/widgets/home_schedule_detail_grid.dart
lib/features/correction/correction_form_page.dart
lib/features/correction/correction_history_page.dart
lib/services/attendance_correction_service.dart
lib/core/models/attendance_correction.dart
```

---

## 10. Urutan Implementasi Aman

1. Simpan rencana relayout ke dokumen ini.
2. Buat `HomeAttendanceHeroCard` tanpa mengubah logic presensi.
3. Update `HomePage` agar urutan layout menjadi header, hero card, aksi cepat, pengumuman.
4. Update quick action menjadi 7 menu final.
5. Pisahkan filtering notifikasi personal dan pengumuman.
6. Pastikan badge lonceng hanya menghitung notifikasi personal unread.
7. Pastikan pengumuman hanya muncul di Home.
8. Redesign `NotificationsPage` sesuai referensi.
9. Tambahkan rencana/fitur `Koreksi` setelah relayout home stabil.
10. Test flow Clock In, Clock Out, notifikasi, dan pengumuman.

---

## 11. Checklist Validasi

```text
[ ] Home menampilkan header hijau baru
[ ] Card presensi utama tampil di atas
[ ] Status kehadiran tampil akurat
[ ] Clock In / Clock Out tetap memakai validasi lama
[ ] Aksi cepat hanya 7 menu
[ ] Status dihapus dari aksi cepat
[ ] Riwayat dihapus dari aksi cepat
[ ] Koreksi muncul sebagai menu baru / placeholder awal
[ ] Pengumuman tampil di Home di bawah aksi cepat
[ ] Pengumuman tidak muncul di halaman notifikasi personal
[ ] Badge lonceng tidak menghitung pengumuman
[ ] Halaman notifikasi hanya menampilkan approval/status user/sistem personal
[ ] Mark read dan filter unread tetap berjalan
[ ] Tidak ada overflow di layar kecil
[ ] Tidak ada null error saat jadwal belum dimuat
```
