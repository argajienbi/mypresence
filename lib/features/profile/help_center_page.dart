import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_session.dart';
import '../../widgets/app_card.dart';
import '../../widgets/sticky_curve_header.dart';

class HelpCenterPage extends StatelessWidget {
  final AppSession session;

  const HelpCenterPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final faqs = const [
      _FaqItem(
        question: '1. Cara absen masuk',
        answer:
            'Buka menu absen, pastikan lokasi aktif, lalu ambil foto selfie sesuai panduan dan kirim saat jam absen masuk masih dibuka.',
      ),
      _FaqItem(
        question: '2. Cara absen pulang',
        answer:
            'Buka menu absen pulang, cek lokasi dan kamera, ambil foto selfie, lalu kirim setelah waktu pulang sesuai jadwal.',
      ),
      _FaqItem(
        question: '3. Cara menggunakan QR titip absen',
        answer:
            'Scan QR karyawan yang dibantu, lanjut ambil foto bukti, lalu kirim request untuk divalidasi admin.',
      ),
      _FaqItem(
        question: '4. Cara mengajukan izin',
        answer:
            'Buka menu pengajuan, pilih izin, isi tanggal dan alasan, lalu kirim sesuai langkah yang tersedia di aplikasi.',
      ),
      _FaqItem(
        question: '5. Cara mengajukan sakit',
        answer:
            'Pilih menu sakit, isi tanggal dan alasan, lalu lampirkan bukti jika diminta sebelum mengirim pengajuan.',
      ),
      _FaqItem(
        question: '6. Cara mengajukan cuti',
        answer:
            'Pilih cuti, tentukan tanggal mulai dan selesai, isi alasan, lalu kirim pengajuan untuk diverifikasi admin.',
      ),
      _FaqItem(
        question: '7. Cara mengajukan lembur',
        answer:
            'Pilih lembur, isi tanggal, jam mulai, jam selesai, dan alasan pekerjaan lembur sebelum mengirim permintaan.',
      ),
      _FaqItem(
        question: '8. Kenapa lokasi harus aktif',
        answer:
            'Lokasi dipakai untuk memastikan presensi dilakukan di area kerja yang benar. Jika lokasi mati, aplikasi bisa menolak presensi.',
      ),
      _FaqItem(
        question: '9. Kenapa kamera harus diizinkan',
        answer:
            'Kamera digunakan untuk mengambil foto bukti presensi. Tanpa izin kamera, aplikasi tidak bisa melanjutkan proses presensi.',
      ),
      _FaqItem(
        question: '10. Solusi jika gagal absen',
        answer:
            'Cek koneksi internet, lokasi, dan kamera, lalu coba lagi. Jika masih gagal, ulangi beberapa menit kemudian atau hubungi admin.',
      ),
      _FaqItem(
        question: '11. Solusi jika di luar radius kantor',
        answer:
            'Dekatkan posisi Anda ke area kantor yang ditentukan. Jika masih ditolak, pastikan lokasi perangkat akurat dan GPS aktif.',
      ),
      _FaqItem(
        question: '12. Solusi jika QR tidak valid',
        answer:
            'Pastikan QR yang dipindai memang milik karyawan yang dibantu, masih aktif, dan berada di kantor yang sama.',
      ),
      _FaqItem(
        question: '13. Solusi jika notifikasi tidak muncul',
        answer:
            'Periksa izin notifikasi, pengaturan hemat baterai, dan koneksi internet. Buka aplikasi sekali lagi untuk memeriksa pembaruan.',
      ),
      _FaqItem(
        question: '14. Cara menghubungi admin perusahaan',
        answer: 'Hubungi admin perusahaan Anda untuk bantuan lebih lanjut.',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          StickyCurveHeader(
            title: 'Pusat Bantuan',
            subtitle: 'Panduan penggunaan aplikasi untuk ${session.officeName.isEmpty ? 'karyawan' : session.officeName}',
            icon: Icons.help_outline_rounded,
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
                  child: const Text(
                    'Berikut jawaban singkat untuk pertanyaan yang paling sering muncul saat menggunakan aplikasi presensi.',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ...faqs.map(
                  (faq) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FaqCard(item: faq),
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

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}

class _FaqCard extends StatelessWidget {
  final _FaqItem item;

  const _FaqCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.help_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.question,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.answer,
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
