import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

class AttendanceSegmentButton extends StatelessWidget {
  final String nextAction;
  final bool insideRadius;
  final bool hasIn;
  final bool hasOut;
  final VoidCallback onPressed;

  const AttendanceSegmentButton({
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
    final checkInTarget = nextAction == 'masuk' && !done;
    final checkOutTarget = nextAction == 'pulang' && !done;
    final checkInActive = checkInTarget && _canAct;
    final checkOutActive = checkOutTarget && _canAct;
    final checkInDone = hasIn;
    final checkOutDone = hasOut;
    final arrowTurns = done
        ? .25
        : nextAction == 'masuk'
            ? .50
            : 0.0;

    final leftColor = done
        ? AppColors.green
        : checkInTarget
            ? AppColors.green
            : checkInDone
                ? const Color(0xFF7A8793)
                : const Color(0xFF9CA3AF);
    final rightColor = done
        ? AppColors.green
        : checkOutTarget
            ? AppColors.green
            : const Color(0xFF8F969E);

    return SizedBox(
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(56),
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .16),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(52),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentHalf(
                      title: 'Check-In',
                      subtitle: '(Masuk)',
                      icon: checkInDone ? Icons.check_rounded : Icons.fingerprint_rounded,
                      color: leftColor,
                      active: checkInActive,
                      enabled: checkInActive,
                      alignLeft: true,
                      onTap: checkInActive ? onPressed : null,
                    ),
                  ),
                  Container(width: 2.5, color: Colors.white),
                  Expanded(
                    child: _SegmentHalf(
                      title: 'Check-Out',
                      subtitle: '(Pulang)',
                      icon: checkOutDone ? Icons.check_rounded : Icons.fingerprint_rounded,
                      color: rightColor,
                      active: checkOutActive,
                      enabled: checkOutActive,
                      alignLeft: false,
                      onTap: checkOutActive ? onPressed : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _canAct ? onPressed : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: AnimatedRotation(
                turns: arrowTurns,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 38,
                  color: done ? AppColors.green : AppColors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentHalf extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool active;
  final bool enabled;
  final bool alignLeft;
  final VoidCallback? onTap;

  const _SegmentHalf({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.active,
    required this.enabled,
    required this.alignLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          color: color,
          padding: EdgeInsets.only(
            left: alignLeft ? 20 : 34,
            right: alignLeft ? 34 : 20,
          ),
          child: Opacity(
            opacity: enabled || active ? 1 : .92,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 29),
                const SizedBox(width: 9),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .90),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
