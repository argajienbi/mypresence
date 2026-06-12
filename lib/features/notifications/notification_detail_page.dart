import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_notification.dart';
import '../../core/models/app_session.dart';
import '../../services/notification_router.dart';

class NotificationDetailPage extends StatelessWidget {
  final AppSession session;
  final AppNotification notification;

  const NotificationDetailPage({
    super.key,
    required this.session,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final category = _NotificationDetailCategory.from(notification);
    final hasReference = notification.refType.trim().isNotEmpty ||
        notification.refId.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            _DetailHeader(onBack: () => Navigator.of(context).pop()),
            const SizedBox(height: 18),
            _HeroIcon(category: category),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: .08)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .06),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Badge(
                      label: category.label.toUpperCase(),
                      color: category.color),
                  const SizedBox(height: 12),
                  Text(
                    notification.title.trim().isEmpty
                        ? 'MYPRESENSI'
                        : notification.title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.16,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          color: AppColors.muted, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatLongTime(notification.createdAt),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _MessageCard(
                      notification: notification, color: category.color),
                  const SizedBox(height: 16),
                  _DetailInfoCard(
                      notification: notification, category: category),
                  const SizedBox(height: 16),
                  _InformationBox(
                      color: category.color, refType: notification.refType),
                  if (hasReference) ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => NotificationRouter.openFromNotification(
                          context,
                          session,
                          notification,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Text(_referenceButtonLabel(notification.refType),
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _referenceButtonLabel(String refType) {
    final type = refType.toLowerCase();
    if (type.contains('attendance_reminder') || type.contains('reminder')) {
      return 'Buka Beranda';
    }
    if (type.contains('leave') || type.contains('approval')) {
      return 'Lihat Detail Pengajuan';
    }
    if (type.contains('correction') || type.contains('koreksi')) {
      return 'Lihat Detail Koreksi';
    }
    if (type.contains('qr')) {
      return 'Lihat Status QR';
    }
    if (type.contains('attendance')) {
      return 'Lihat Riwayat Presensi';
    }
    if (type.contains('schedule') || type.contains('jadwal')) {
      return 'Lihat Detail Jadwal';
    }
    return 'Lihat Detail';
  }

  static String _formatLongTime(int timestamp) {
    if (timestamp <= 0) return 'Waktu tidak tersedia';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final months = const [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _DetailHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: .78),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_back_rounded,
                    color: AppColors.text, size: 25),
              ),
            ),
          ),
          const Spacer(),
          const Icon(Icons.more_vert_rounded, color: AppColors.text),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final _NotificationDetailCategory category;

  const _HeroIcon({required this.category});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: category.color.withValues(alpha: .08))),
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [
                category.color.withValues(alpha: .82),
                category.color
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(
                    color: category.color.withValues(alpha: .28),
                    blurRadius: 28,
                    offset: const Offset(0, 12))
              ],
            ),
            child: Icon(category.icon, color: Colors.white, size: 52),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final AppNotification notification;
  final Color color;

  const _MessageCard({required this.notification, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .12)),
      ),
      child: Text(notification.displayBody,
          style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              height: 1.55,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _DetailInfoCard extends StatelessWidget {
  final AppNotification notification;
  final _NotificationDetailCategory category;

  const _DetailInfoCard({required this.notification, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detail Notifikasi',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          _DetailRow(label: 'Kategori', value: category.label),
          _DetailRow(
              label: 'Pengirim',
              value:
                  '${notification.displaySender} · ${notification.displaySenderRole}'),
          _DetailRow(
              label: 'Sumber', value: _referenceLabel(notification.refType)),
          _DetailRow(
              label: 'ID Referensi',
              value:
                  notification.refId.trim().isEmpty ? '-' : notification.refId),
          _DetailRow(
              label: 'Status',
              value: _statusLabel(notification),
              valueColor: category.color,
              isLast: true),
        ],
      ),
    );
  }

  static String _referenceLabel(String refType) {
    final type = refType.toLowerCase();
    if (type.contains('attendance_reminder') || type.contains('reminder')) {
      return 'Pengingat Absen';
    }
    if (type.contains('leave') || type.contains('approval')) return 'Pengajuan';
    if (type.contains('correction') || type.contains('koreksi')) {
      return 'Koreksi Presensi';
    }
    if (type.contains('qr') || type.contains('attendance')) {
      return 'Riwayat Presensi';
    }
    if (type.contains('schedule') || type.contains('jadwal')) {
      return 'Jadwal Kerja';
    }
    if (type.contains('system')) return 'Sistem';
    return 'Notifikasi';
  }

  static String _statusLabel(AppNotification notification) {
    final value =
        '${notification.type} ${notification.title} ${notification.displayBody}'
            .toLowerCase();
    if (value.contains('approved') ||
        value.contains('disetujui') ||
        value.contains('success')) {
      return 'Disetujui';
    }
    if (value.contains('rejected') ||
        value.contains('ditolak') ||
        value.contains('error')) {
      return 'Ditolak';
    }
    if (value.contains('pending') ||
        value.contains('menunggu') ||
        value.contains('review') ||
        value.contains('warning')) {
      return 'Menunggu';
    }
    return notification.read ? 'Sudah dibaca' : 'Belum dibaca';
  }
}

class _InformationBox extends StatelessWidget {
  final Color color;
  final String refType;

  const _InformationBox({required this.color, required this.refType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: .14), shape: BoxShape.circle),
              child: Icon(Icons.info_rounded, color: color, size: 18)),
          const SizedBox(width: 11),
          Expanded(
              child: Text(_infoText(refType),
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.42))),
        ],
      ),
    );
  }

  static String _infoText(String refType) {
    final type = refType.toLowerCase();
    if (type.contains('attendance_reminder') || type.contains('reminder')) {
      return 'Silakan buka Home untuk melihat jadwal dan melakukan absen sesuai waktu yang sudah ditentukan.';
    }
    if (type.contains('schedule') || type.contains('jadwal')) {
      return 'Silakan cek detail jadwal untuk melihat perubahan jam kerja atau shift terbaru.';
    }
    if (type.contains('attendance') || type.contains('qr')) {
      return 'Silakan cek riwayat presensi untuk melihat detail validasi dan bukti presensi.';
    }
    if (type.contains('correction') || type.contains('koreksi')) {
      return 'Silakan cek detail koreksi untuk melihat status review dari admin.';
    }
    if (type.contains('leave') || type.contains('approval')) {
      return 'Silakan cek detail pengajuan untuk informasi lebih lengkap.';
    }
    return 'Informasi ini bersifat personal untuk akun Anda.';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _DetailRow(
      {required this.label,
      required this.value,
      this.valueColor,
      this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w800))),
          const SizedBox(width: 12),
          Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: valueColor ?? AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1.3))),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }
}

class _NotificationDetailCategory {
  final String label;
  final IconData icon;
  final Color color;

  const _NotificationDetailCategory(
      {required this.label, required this.icon, required this.color});

  factory _NotificationDetailCategory.from(AppNotification notification) {
    final value =
        '${notification.type} ${notification.refType} ${notification.title} ${notification.displayBody}'
            .toLowerCase();
    if (value.contains('attendance_reminder') || value.contains('reminder')) {
      return const _NotificationDetailCategory(
          label: 'Pengingat',
          icon: Icons.alarm_rounded,
          color: AppColors.blue);
    }
    if (value.contains('correction') || value.contains('koreksi')) {
      return const _NotificationDetailCategory(
          label: 'Koreksi',
          icon: Icons.edit_note_rounded,
          color: AppColors.orange);
    }
    if (value.contains('schedule') || value.contains('jadwal')) {
      return const _NotificationDetailCategory(
          label: 'Jadwal',
          icon: Icons.calendar_month_rounded,
          color: AppColors.blue);
    }
    if (value.contains('qr')) {
      return const _NotificationDetailCategory(
          label: 'Presensi',
          icon: Icons.qr_code_2_rounded,
          color: AppColors.purple);
    }
    if (value.contains('attendance') ||
        value.contains('presensi') ||
        value.contains('absensi')) {
      return const _NotificationDetailCategory(
          label: 'Presensi',
          icon: Icons.fact_check_rounded,
          color: AppColors.purple);
    }
    if (value.contains('system') ||
        value.contains('sistem') ||
        value.contains('user_status') ||
        value.contains('status_update')) {
      return const _NotificationDetailCategory(
          label: 'Sistem',
          icon: Icons.settings_rounded,
          color: AppColors.muted);
    }
    if (value.contains('warning') ||
        value.contains('pending') ||
        value.contains('menunggu')) {
      return const _NotificationDetailCategory(
          label: 'Approval',
          icon: Icons.pending_actions_rounded,
          color: AppColors.orange);
    }
    if (value.contains('rejected') ||
        value.contains('ditolak') ||
        value.contains('error')) {
      return const _NotificationDetailCategory(
          label: 'Approval', icon: Icons.error_rounded, color: AppColors.red);
    }
    return const _NotificationDetailCategory(
        label: 'Approval', icon: Icons.check_rounded, color: AppColors.green);
  }
}
