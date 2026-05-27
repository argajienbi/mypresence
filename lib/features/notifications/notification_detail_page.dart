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
    final color = _typeColor(notification.type, notification.refType);
    final hasReference = notification.refType.trim().isNotEmpty || notification.refId.trim().isNotEmpty;
    final referenceLabel = _referenceLabel(notification.refType);
    final buttonLabel = _referenceButtonLabel(notification.refType);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Detail Notifikasi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withValues(alpha: .06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: color.withValues(alpha: .12),
                      child: Icon(_typeIcon(notification.type, notification.refType), color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Badge(label: notification.displayType, color: color),
                          const SizedBox(height: 8),
                          Text(
                            notification.title.trim().isEmpty ? 'MY PRESENCE' : notification.title,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              height: 1.18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  notification.displayBody,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                _InfoRow(
                  icon: Icons.person_rounded,
                  label: 'Pengirim',
                  value: '${notification.displaySender} · ${notification.displaySenderRole}',
                ),
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Waktu',
                  value: _formatTime(notification.createdAt),
                ),
                if (hasReference)
                  _InfoRow(
                    icon: Icons.link_rounded,
                    label: 'Sumber',
                    value: referenceLabel,
                  ),
                if (hasReference) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => NotificationRouter.openReference(
                        context,
                        session,
                        notification.refType,
                        notification.refId,
                      ),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(buttonLabel),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _typeColor(String type, String refType) {
    final value = '$type $refType'.toLowerCase();
    if (value.contains('success') || value.contains('approved')) return AppColors.green;
    if (value.contains('warning') || value.contains('pending')) return AppColors.orange;
    if (value.contains('danger') || value.contains('error') || value.contains('rejected')) return AppColors.red;
    return AppColors.primary;
  }

  static IconData _typeIcon(String type, String refType) {
    final value = '$type $refType'.toLowerCase();
    if (value.contains('announcement')) return Icons.campaign_rounded;
    if (value.contains('success') || value.contains('approved')) return Icons.check_circle_rounded;
    if (value.contains('warning') || value.contains('pending')) return Icons.warning_rounded;
    if (value.contains('danger') || value.contains('error') || value.contains('rejected')) return Icons.error_rounded;
    if (value.contains('attendance') || value.contains('qr')) return Icons.fact_check_rounded;
    return Icons.notifications_rounded;
  }

  static String _referenceLabel(String refType) {
    final type = refType.toLowerCase();
    if (type.contains('announcement')) return 'Pengumuman';
    if (type.contains('leave')) return 'Pengajuan';
    if (type.contains('qr') || type.contains('attendance')) return 'Riwayat Presensi';
    if (type.contains('schedule') || type.contains('jadwal')) return 'Jadwal Kerja';
    return 'Notifikasi';
  }

  static String _referenceButtonLabel(String refType) {
    final type = refType.toLowerCase();
    if (type.contains('announcement')) return 'Lihat Pengumuman';
    if (type.contains('leave')) return 'Lihat Pengajuan';
    if (type.contains('qr') || type.contains('attendance')) return 'Lihat Riwayat';
    if (type.contains('schedule') || type.contains('jadwal')) return 'Lihat Jadwal';
    return 'Lihat Detail';
  }

  static String _formatTime(int timestamp) {
    if (timestamp <= 0) return 'Waktu tidak tersedia';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
