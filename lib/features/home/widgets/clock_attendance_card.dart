import 'package:flutter/material.dart';

/// Kartu absen gaya Tiket V2 (dikunci 2026-10-19, mockup card-absen.html).
/// Perforasi + stub tanggal, panel info Terakhir & Berikutnya.
/// Seluruh props & logika status dipertahankan; lastLabel/nextLabel opsional.
class ClockAttendanceCard extends StatelessWidget {
  final String nextAction;
  final bool insideRadius;
  final bool hasIn;
  final bool hasOut;
  final String? checkInTime;
  final String? checkOutTime;
  final String? lastLabel;
  final String? nextLabel;
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
    this.lastLabel,
    this.nextLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = nextAction == 'done' && hasIn && hasOut;
    final isClockIn = nextAction == 'masuk' && !isDone;
    final isClockOut = nextAction == 'pulang' && !isDone;
    final isInteractive = isClockIn || isClockOut;

    final checkIn = _formatTime(checkInTime);
    final checkOut = _formatTime(checkOutTime);
    final now = DateTime.now();

    late final String title;
    late final String subtitle;
    late final LinearGradient gradient;
    late final Color shadowColor;

    if (isDone) {
      title = 'Presensi Selesai';
      subtitle = 'Tiket hari ini sudah terpakai';
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF16A34A), Color(0xFF15803D)],
      );
      shadowColor = const Color(0xFF15803D).withValues(alpha: .30);
    } else if (isClockOut) {
      title = 'Absen Pulang';
      subtitle = 'Tap untuk robek tiket pulang';
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF6B35), Color(0xFFE8590C)],
      );
      shadowColor = const Color(0xFFE8590C).withValues(alpha: .32);
    } else {
      title = 'Absen Masuk';
      subtitle = 'Tap untuk robek tiket masuk';
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B5ED7), Color(0xFF084298)],
      );
      shadowColor = const Color(0xFF084298).withValues(alpha: .34);
    }

    // Info waktu: fallback ke jam absen hari ini bila label tak diberikan.
    final lastInfo = (lastLabel?.trim().isNotEmpty ?? false)
        ? lastLabel!.trim()
        : (hasOut
            ? 'Pulang $checkOut'
            : hasIn
                ? 'Masuk $checkIn'
                : '-');
    final nextInfo = (nextLabel?.trim().isNotEmpty ?? false)
        ? nextLabel!.trim()
        : '-';

    final contentKey = ValueKey('$nextAction|$checkIn|$checkOut');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isInteractive ? onPressed : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stub tanggal
                    Container(
                      width: 74,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 6,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            now.day.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _monthAbbr(now.month).toUpperCase(),
                            style: TextStyle(
                              color:
                                  Colors.white.withValues(alpha: .85),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Garis perforasi vertikal
                    SizedBox(
                      width: 2,
                      child: CustomPaint(
                        painter: const _DashedLinePainter(vertical: true),
                      ),
                    ),
                    // Konten utama
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, .06),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: Column(
                            key: contentKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: .20),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isDone
                                          ? Icons.check_rounded
                                          : Icons
                                              .photo_camera_front_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: .88),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.black.withValues(alpha: .14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _TimeRow(
                                      label: 'Terakhir',
                                      value: lastInfo,
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: SizedBox(
                                        height: 1,
                                        width: double.infinity,
                                        child: CustomPaint(
                                          painter: _DashedLinePainter(
                                              vertical: false),
                                        ),
                                      ),
                                    ),
                                    _TimeRow(
                                      label: 'Berikutnya',
                                      value: nextInfo,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Notch perforasi atas & bawah
                const Positioned(
                  left: 63,
                  top: -11,
                  child: _Notch(),
                ),
                const Positioned(
                  left: 63,
                  bottom: -11,
                  child: _Notch(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? '--:--' : text;
  }

  String _monthAbbr(int month) {
    const abbr = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return abbr[month - 1];
  }
}

class _Notch extends StatelessWidget {
  const _Notch();

  @override
  Widget build(BuildContext context) {
    // Warna = background halaman agar terlihat seperti lubang tiket.
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String value;

  const _TimeRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .75),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final bool vertical;

  const _DashedLinePainter({required this.vertical});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .45)
      ..strokeWidth = vertical ? 2 : 1;
    const dash = 5.0;
    const gap = 4.0;
    if (vertical) {
      double y = 4;
      while (y < size.height - 4) {
        final end = (y + dash).clamp(0.0, size.height - 4);
        canvas.drawLine(Offset(size.width / 2, y),
            Offset(size.width / 2, end), paint);
        y += dash + gap;
      }
    } else {
      double x = 0;
      while (x < size.width) {
        final end = (x + dash).clamp(0.0, size.width);
        canvas.drawLine(Offset(x, 0), Offset(end, 0), paint);
        x += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
