import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../widgets/app_card.dart';

class QuickMenu extends StatelessWidget {
  final VoidCallback onIzin;
  final VoidCallback onSakit;
  final VoidCallback onCuti;
  final VoidCallback onLembur;
  final VoidCallback onQrTeman;
  final VoidCallback onNotifikasi;
  final int unreadNotifications;

  const QuickMenu({
    super.key,
    required this.onIzin,
    required this.onSakit,
    required this.onCuti,
    required this.onLembur,
    required this.onQrTeman,
    required this.onNotifikasi,
    this.unreadNotifications = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _Item(label: 'Izin', icon: Icons.event_note_rounded, color: AppColors.primary, onTap: onIzin),
            const SizedBox(width: 10),
            _Item(label: 'Sakit', icon: Icons.medical_services_rounded, color: AppColors.red, onTap: onSakit),
            const SizedBox(width: 10),
            _Item(label: 'Cuti', icon: Icons.work_rounded, color: AppColors.orange, onTap: onCuti),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _Item(label: 'Lembur', icon: Icons.more_time_rounded, color: const Color(0xFF7C3AED), onTap: onLembur),
            const SizedBox(width: 10),
            _Item(label: 'QR', icon: Icons.qr_code_2_rounded, color: AppColors.green, onTap: onQrTeman),
            const SizedBox(width: 10),
            _Item(
              label: 'Notifikasi',
              icon: Icons.notifications_rounded,
              color: AppColors.orange,
              onTap: onNotifikasi,
              badge: unreadNotifications,
            ),
          ],
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int badge;

  const _Item({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .11),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    right: 10,
                    top: 9,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
