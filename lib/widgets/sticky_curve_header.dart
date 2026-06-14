import 'package:flutter/material.dart';

class StickyCurveHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Widget? extra;
  final double height;
  final bool showAccent;

  const StickyCurveHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.trailing,
    this.extra,
    this.height = 112,
    this.showAccent = true,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final totalHeight = top + height;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _StickyCurveHeaderPainter(showAccent: showAccent),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(icon, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .90),
                            fontSize: 14,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (extra != null) ...[
                          const SizedBox(height: 8),
                          extra!,
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyCurveHeaderPainter extends CustomPainter {
  final bool showAccent;

  const _StickyCurveHeaderPainter({required this.showAccent});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF08B65F), Color(0xFF078FAF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    final path = Path()
      ..lineTo(0, size.height - 36)
      ..quadraticBezierTo(
        size.width * .50,
        size.height + 18,
        size.width,
        size.height - 36,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);

    if (!showAccent) return;

    final accentPaint = Paint()
      ..color = Colors.white.withValues(alpha: .06)
      ..style = PaintingStyle.fill;

    final accentPath = Path()
      ..moveTo(size.width * .42, 0)
      ..cubicTo(
        size.width * .72,
        20,
        size.width * .86,
        78,
        size.width,
        58,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(accentPath, accentPaint);
  }

  @override
  bool shouldRepaint(covariant _StickyCurveHeaderPainter oldDelegate) {
    return oldDelegate.showAccent != showAccent;
  }
}
