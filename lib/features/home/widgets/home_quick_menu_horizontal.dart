import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../widgets/app_card.dart';

class HomeQuickMenuHorizontal extends StatelessWidget {
  final VoidCallback onStatus;
  final VoidCallback onSchedule;
  final VoidCallback onIzin;
  final VoidCallback onSakit;
  final VoidCallback onCuti;
  final VoidCallback onLembur;
  final VoidCallback onQrTeman;

  const HomeQuickMenuHorizontal({
    super.key,
    required this.onStatus,
    required this.onSchedule,
    required this.onIzin,
    required this.onSakit,
    required this.onCuti,
    required this.onLembur,
    required this.onQrTeman,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          _MenuItem(
            label: 'Status',
            icon: Icons.assignment_turned_in_rounded,
            color: const Color(0xFF7A8793),
            onTap: onStatus,
          ),
          const SizedBox(width: 12),
          _MenuItem(
            label: 'Detail Jadwal',
            icon: Icons.event_available_rounded,
            color: AppColors.primary,
            onTap: onSchedule,
          ),
          const SizedBox(width: 12),
          _MenuItem(
            label: 'Izin',
            icon: Icons.event_note_rounded,
            color: AppColors.primary,
            onTap: onIzin,
          ),
          const SizedBox(width: 12),
          _MenuItem(
            label: 'Sakit',
            icon: Icons.medical_services_rounded,
            color: AppColors.red,
            onTap: onSakit,
          ),
          const SizedBox(width: 12),
          _MenuItem(
            label: 'Cuti',
            icon: Icons.work_rounded,
            color: AppColors.orange,
            onTap: onCuti,
          ),
          const SizedBox(width: 12),
          _MenuItem(
            label: 'Lembur',
            icon: Icons.more_time_rounded,
            color: const Color(0xFF7C3AED),
            onTap: onLembur,
          ),
          const SizedBox(width: 12),
          _MenuItem(
            label: 'QR',
            icon: Icons.qr_code_2_rounded,
            color: AppColors.green,
            onTap: onQrTeman,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          width: 76,
          height: 76,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
