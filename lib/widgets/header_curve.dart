import 'package:flutter/material.dart';

import '../app/theme.dart';

class HeaderCurve extends StatelessWidget {
  final double height;

  const HeaderCurve({
    super.key,
    this.height = 170,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _HeaderCurveClipper(),
      child: Container(
        height: height,
        color: AppColors.headerCurve,
      ),
    );
  }
}

class _HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width * 0.52,
      size.height + 22,
      size.width,
      size.height - 42,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
