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
            subtitle: hasIn ? 'Selesai' : clockInActive ? 'Masuk' : 'Menunggu',
            icon: hasIn ? Icons.check_rounded : Icons.fingerprint_rounded,
            accentColor: AppColors.green,
            active: clockInActive,
            completed: hasIn,
            onTap: clockInActive ? onPressed : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ClockActionCard(
            title: 'Clock Out',
            subtitle:
                hasOut ? 'Selesai' : clockOutActive ? 'Pulang' : 'Menunggu',
            icon: hasOut ? Icons.check_rounded : Icons.fingerprint_rounded,
            accentColor: AppColors.blue,
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
  final Color accentColor;
  final bool active;
  final bool completed;
  final VoidCallback? onTap;

  const _ClockActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.active,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isInteractive = active && onTap != null;
    final isHighlighted = active || completed;
    final gradient = completed
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF42C974),
              const Color(0xFF179A57),
            ],
          )
        : active
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accentColor.withValues(alpha: .98),
                  Color.lerp(accentColor, Colors.black, .18) ?? accentColor,
                ],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF7FAFD),
                  Color(0xFFE8EEF5),
                ],
              );
    final borderColor = completed
        ? Colors.white.withValues(alpha: .24)
        : active
            ? Colors.white.withValues(alpha: .24)
            : AppColors.line;
    final shadowColor = completed
        ? const Color(0xFF179A57).withValues(alpha: .34)
        : active
            ? accentColor.withValues(alpha: .30)
            : Colors.black.withValues(alpha: .08);
    final contentColor = isHighlighted ? Colors.white : AppColors.text;
    final mutedColor = isHighlighted
        ? Colors.white.withValues(alpha: .88)
        : AppColors.muted;
    final iconColor = completed
        ? const Color(0xFF179A57)
        : active
            ? accentColor
            : const Color(0xFF9AA5B1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          height: 108,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: gradient,
            border: Border.all(color: borderColor, width: active ? 1.2 : 1),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: active || completed ? 22 : 18,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: .24),
                          Colors.transparent,
                          Colors.black.withValues(alpha: .08),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .10),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: iconColor, size: 27),
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
                            color: contentColor,
                            fontSize: 15.2,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (active)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .22),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: .30)),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    )
                  else
                    const SizedBox(width: 36, height: 36),
                ],
              ),
              if (isInteractive)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: .16),
                          Colors.transparent,
                        ],
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
