import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../widgets/app_card.dart';

class ClockAttendanceCard extends StatelessWidget {
  final String nextAction;
  final bool insideRadius;
  final bool hasIn;
  final bool hasOut;
  final VoidCallback onPressed;

  const ClockAttendanceCard({
    super.key,
    required this.nextAction,
    required this.insideRadius,
    required this.hasIn,
    required this.hasOut,
    required this.onPressed,
  });

  bool get _canAct => nextAction != 'done';

  @override
  Widget build(BuildContext context) {
    final done = nextAction == 'done';
    final clockInTarget = nextAction == 'masuk' && !done;
    final clockOutTarget = nextAction == 'pulang' && !done;
    final clockInActive = clockInTarget && _canAct;
    final clockOutActive = clockOutTarget && _canAct;
    final clockInDone = hasIn;
    final clockOutDone = hasOut;

    final leftColor = done
        ? AppColors.green
        : clockInTarget
            ? AppColors.green
            : clockInDone
                ? const Color(0xFF9CA3AF)
                : const Color(0xFFD1D5DB);
    final rightColor = done
        ? AppColors.green
        : clockOutTarget
            ? AppColors.primary
            : const Color(0xFFD1D5DB);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Clock In Button
              Expanded(
                child: _ClockButton(
                  title: 'Clock In',
                  subtitle: 'Masuk',
                  icon: clockInDone
                      ? Icons.check_rounded
                      : Icons.fingerprint_rounded,
                  color: leftColor,
                  active: clockInActive,
                  enabled: clockInActive,
                  onTap: clockInActive ? onPressed : null,
                ),
              ),
              Container(
                width: 1,
                height: 80,
                color: AppColors.line,
              ),
              // Clock Out Button
              Expanded(
                child: _ClockButton(
                  title: 'Clock Out',
                  subtitle: 'Pulang',
                  icon: clockOutDone
                      ? Icons.check_rounded
                      : Icons.fingerprint_rounded,
                  color: rightColor,
                  active: clockOutActive,
                  enabled: clockOutActive,
                  onTap: clockOutActive ? onPressed : null,
                ),
              ),
            ],
          ),
          if (done)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.08),
                border:
                    Border(top: BorderSide(color: AppColors.line, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.green, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Presensi Hari Ini Selesai',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.green,
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

class _ClockButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool active;
  final bool enabled;
  final VoidCallback? onTap;

  const _ClockButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: enabled ? color.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled ? color : const Color(0xFF9CA3AF),
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: enabled ? color : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: enabled ? color : const Color(0xFFB4B9C1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
