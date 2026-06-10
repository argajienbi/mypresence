import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_session.dart';
import '../../widgets/app_card.dart';
import '../../widgets/sticky_curve_header.dart';

class TermsPage extends StatelessWidget {
  final AppSession session;

  const TermsPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final sections = const [
      _PolicySection(
        title: '1. Penggunaan aplikasi MYPRESENCE',
        body:
            'MYPRESENCE digunakan untuk membantu pencatatan presensi, pengajuan keterangan, dan proses terkait kehadiran karyawan sesuai aturan perusahaan.',
      ),
      _PolicySection(
        title: '2. Ketentuan akun karyawan',
        body:
            'Akun digunakan oleh karyawan yang terdaftar dan aktif. Data akun harus benar, tidak dipinjamkan, dan tidak dibagikan ke orang lain.',
      ),
      _PolicySection(
        title: '3. Ketentuan presensi masuk dan pulang',
        body:
            'Presensi masuk dan pulang harus dilakukan sesuai jadwal kerja, lokasi yang ditetapkan, serta metode yang tersedia di aplikasi.',
      ),
      _PolicySection(
        title: '4. Penggunaan lokasi / GPS',
        body:
            'Aplikasi dapat meminta lokasi aktif untuk memastikan presensi dilakukan di area kerja yang sesuai. Jika lokasi dimatikan, presensi bisa gagal.',
      ),
      _PolicySection(
        title: '5. Penggunaan kamera dan foto selfie',
        body:
            'Kamera digunakan untuk mengambil foto bukti presensi. Foto harus jelas, menampilkan wajah pengguna, dan diambil langsung dari perangkat yang digunakan.',
      ),
      _PolicySection(
        title: '6. Ketentuan QR titip absen',
        body:
            'QR titip absen hanya boleh dipakai sesuai aturan perusahaan. Saat ini, QR hanya bisa digunakan oleh karyawan di kantor yang sama dan tetap wajib melampirkan foto bukti.',
      ),
      _PolicySection(
        title: '7. Ketentuan izin, sakit, cuti, dan lembur',
        body:
            'Pengajuan izin, sakit, cuti, dan lembur mengikuti alur yang tersedia. Beberapa jenis pengajuan dapat membutuhkan alasan, lampiran, atau data tambahan.',
      ),
      _PolicySection(
        title: '8. Validasi admin',
        body:
            'Seluruh data presensi dan pengajuan dapat diperiksa, disetujui, atau ditolak oleh admin sesuai kebutuhan operasional perusahaan.',
      ),
      _PolicySection(
        title: '9. Larangan manipulasi data presensi',
        body:
            'Pengguna dilarang memalsukan lokasi, foto, waktu, QR, atau data lain yang berkaitan dengan presensi dan pengajuan.',
      ),
      _PolicySection(
        title: '10. Perubahan data oleh admin/perusahaan',
        body:
            'Admin atau perusahaan dapat melakukan koreksi data jika diperlukan, misalnya untuk penyesuaian jadwal, verifikasi, atau perbaikan data operasional.',
      ),
      _PolicySection(
        title: '11. Batasan tanggung jawab aplikasi',
        body:
            'Aplikasi membantu pencatatan dan pengelolaan data. Keputusan akhir tetap mengikuti kebijakan perusahaan, kondisi jaringan, serta validasi admin.',
      ),
      _PolicySection(
        title: '12. Persetujuan pengguna',
        body:
            'Dengan menggunakan aplikasi, pengguna dianggap memahami dan menyetujui ketentuan yang berlaku, termasuk aturan tambahan dari perusahaan atau admin masing-masing.',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          StickyCurveHeader(
            title: 'Syarat & Ketentuan',
            subtitle: 'Aturan penggunaan aplikasi presensi${session.officeName.isEmpty ? '' : ' - ${session.officeName}'}',
            icon: Icons.description_outlined,
            height: 108,
          ),
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(16),
                  radius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ketentuan penggunaan',
                        style: TextStyle(
                          color: AppColors.primary.withValues(alpha: .92),
                          fontWeight: FontWeight.w900,
                          letterSpacing: .2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ketentuan ini membantu memastikan penggunaan aplikasi tetap tertib, aman, dan sesuai kebijakan perusahaan.',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ...sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PolicySectionCard(section: section),
                  ),
                ),
                const SizedBox(height: 4),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  radius: 22,
                  child: const Text(
                    'Catatan: aturan final mengikuti kebijakan perusahaan atau admin masing-masing dan dapat diperbarui sewaktu-waktu.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
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
}

class _PolicySection {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});
}

class _PolicySectionCard extends StatelessWidget {
  final _PolicySection section;

  const _PolicySectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
