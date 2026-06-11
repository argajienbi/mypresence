import 'package:flutter/material.dart';

class ClockAttendanceCard extends StatelessWidget {
  final String nextAction;
  final bool insideRadius;
  final bool hasIn;
  final bool hasOut;
  final String? checkInTime;
  final String? checkOutTime;
  final VoidCallback onPressed;

  const ClockAttendanceCard({
    super.key,
    required this.nextAction,
    required this.insideRadius,
    required this.hasIn,
    required this.hasOut,
    required this.onPressed,
    this.checkInTime,
    this.checkOutTime,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = nextAction == 'done' && hasIn && hasOut;
    final isClockIn = nextAction == 'masuk' && !isDone;
    final isClockOut = nextAction == 'pulang' && !isDone;
    final isInteractive = isClockIn || isClockOut;

    final checkIn = _formatTime(checkInTime);
    final checkOut = _formatTime(checkOutTime);

    late final String title;
    late final String subtitle;
    late final String info;
    late final LinearGradient gradient;
    late final Color shadowColor;
    late final Color accentColor;

    if (isDone) {
      title = 'Presensi Selesai';
      subtitle = 'Anda sudah absen masuk & pulang';
      info = 'Masuk $checkIn | Pulang $checkOut';
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF29B766),
          Color(0xFF0C8E53),
        ],
      );
      shadowColor = const Color(0xFF0C8E53).withValues(alpha: .34);
      accentColor = const Color(0xFF169A58);
    } else if (isClockOut) {
      title = 'Absen Pulang';
      subtitle = 'Tap untuk selfie presensi pulang';
      info = 'Masuk $checkIn';
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0E9ADA),
          Color(0xFF17B4C2),
        ],
      );
      shadowColor = const Color(0xFF0E9ADA).withValues(alpha: .32);
      accentColor = const Color(0xFF0D94D4);
    } else {
      title = 'Absen Masuk';
      subtitle = 'Tap untuk selfie presensi masuk';
      info = 'Belum absen';
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1FB55F),
          Color(0xFF0D9053),
        ],
      );
      shadowColor = const Color(0xFF1FB55F).withValues(alpha: .32);
      accentColor = const Color(0xFF18A55A);
    }

    final contentKey = ValueKey('$nextAction|$checkIn|$checkOut');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isInteractive ? onPressed : null,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: 122,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: gradient,
            border: Border.all(
              color: Colors.white.withValues(alpha: .22),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 26,
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
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: .18),
                          Colors.transparent,
                          Colors.black.withValues(alpha: .10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .10),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.photo_camera_front_rounded,
                      color: accentColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final offset = Tween<Offset>(
                          begin: const Offset(0, .08),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: offset, child: child),
                        );
                      },
                      child: _AttendanceContent(
                        key: contentKey,
                        title: title,
                        subtitle: subtitle,
                        info: info,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: isInteractive
                        ? Container(
                            key: const ValueKey('arrow'),
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .28),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          )
                        : const SizedBox(
                            key: ValueKey('done-spacer'),
                            width: 42,
                            height: 42,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? '--:--' : text;
  }
}

class _AttendanceContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final String info;

  const _AttendanceContent({
    super.key,
    required this.title,
    required this.subtitle,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey('$title|$subtitle|$info'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15.5,
            fontWeight: FontWeight.w900,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .90),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: .18)),
          ),
          child: Text(
            info,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
