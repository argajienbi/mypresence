import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../widgets/app_card.dart';

class TodayStatusCard extends StatelessWidget {
  final String status;
  final String checkIn;
  final String checkOut;
  final bool completed;

  const TodayStatusCard({
    super.key,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final hasCheckIn = checkIn != '--:--';
    final badge = completed ? 'Lengkap' : hasCheckIn ? 'Tercatat' : 'Belum Absen';
    final color = completed ? AppColors.green : hasCheckIn ? AppColors.primary : AppColors.muted;
    final helper = completed
        ? 'Presensi hari ini sudah lengkap.'
        : hasCheckIn
            ? 'Silakan lakukan absen pulang.'
            : 'Silakan lakukan absen masuk sesuai jadwal.';

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(completed ? Icons.verified_rounded : Icons.event_available_rounded, color: color, size: 25),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Status Hari Ini',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.text),
                      ),
                    ),
                    _Badge(label: badge, color: color),
                  ],
                ),
                const SizedBox(height: 6),
                Text(status, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: AppColors.text)),
                const SizedBox(height: 4),
                Text('Masuk $checkIn • Pulang $checkOut', style: const TextStyle(fontSize: 12.5, color: AppColors.text, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(helper, style: const TextStyle(fontSize: 11.8, color: AppColors.muted, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900)),
    );
  }
}
