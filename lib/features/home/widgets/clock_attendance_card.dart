import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final done = nextAction == 'done';
    final clockInActive = nextAction == 'masuk' && !done;
    final clockOutActive = nextAction == 'pulang' && !done;

    return Row(
      children: [
        Expanded(
          child: _ClockActionCard(
            title: 'Clock In',
            subtitle: hasIn ? 'Sudah masuk' : 'Masuk',
            icon: hasIn ? Icons.check_rounded : Icons.fingerprint_rounded,
            color: AppColors.green,
            active: clockInActive,
            completed: hasIn,
            onTap: clockInActive ? onPressed : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ClockActionCard(
            title: 'Clock Out',
            subtitle: hasOut ? 'Sudah pulang' : 'Pulang',
            icon: hasOut ? Icons.check_rounded : Icons.fingerprint_rounded,
            color: AppColors.blue,
            active: clockOutActive,
            completed: hasOut,
            onTap: clockOutActive ? onPressed : null,
          ),
        ),
      ],
    );
  }
}

class _ClockActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool active;
  final bool completed;
  final VoidCallback? onTap;

  const _ClockActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.active,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = active;
    final visualColor = completed ? AppColors.green : active ? color : const Color(0xFF9CA3AF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 92,
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: .12)
                : completed
                    ? AppColors.green.withValues(alpha: .08)
                    : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: active
                  ? color.withValues(alpha: .35)
                  : completed
                      ? AppColors.green.withValues(alpha: .30)
                      : AppColors.line,
              width: active ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .07),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: visualColor.withValues(alpha: enabled || completed ? .15 : .10),
                ),
                child: Icon(icon, color: visualColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: active || completed ? AppColors.text : const Color(0xFF8E98A5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: visualColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: visualColor.withValues(alpha: active ? .16 : .10),
                ),
                child: Icon(
                  completed ? Icons.check_rounded : Icons.chevron_right_rounded,
                  color: visualColor,
                  size: 23,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
