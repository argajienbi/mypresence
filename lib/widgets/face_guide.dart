import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Panduan wajah di atas pratinjau kamera (mockup absensi): oval
/// putus-putus + busur bahu + caption "Posisikan wajah di dalam bingkai".
/// Dipakai halaman kamera selfie (absensi) dan kamera QR (foto karyawan
/// yang dibantu). Tampil hanya saat kamera siap dan belum ada foto.
class FaceGuide extends StatelessWidget {
  const FaceGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 190,
          height: 210,
          child: CustomPaint(painter: _FaceGuidePainter()),
        ),
        const SizedBox(height: 6),
        const Text(
          'Posisikan wajah di dalam bingkai',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    // Oval wajah 140x165, terpusat horizontal.
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, 82.5),
      width: 140,
      height: 165,
    );
    canvas.drawPath(_dashed(Path()..addOval(ovalRect)), paint);
    // Busur bahu: setengah elips atas (lebar 190, tinggi 110).
    final shoulderRect = Rect.fromCenter(
      center: Offset(size.width / 2, 210),
      width: 190,
      height: 110,
    );
    canvas.drawPath(
      _dashed(Path()..addArc(shoulderRect, math.pi, math.pi)),
      paint,
    );
  }

  Path _dashed(Path source, [double dash = 7, double gap = 6]) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        dashed.addPath(metric.extractPath(distance, end), Offset.zero);
        distance += dash + gap;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
