import 'package:flutter/material.dart';

class StickyCurveHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Widget? extra;
  final double height;

  const StickyCurveHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.trailing,
    this.extra,
    this.height = 112,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final totalHeight = top + height;

    return SizedBox(
      height: totalHeight,
      child: ClipPath(
        clipper: const _StickyCurveClipper(),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, top + 12, 20, 26),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF13A456), Color(0xFF0E8FA3)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.white, size: 23),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
              if (extra != null) ...[
                const SizedBox(height: 10),
                extra!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyCurveClipper extends CustomClipper<Path> {
  const _StickyCurveClipper();

  @override
  Path getClip(Size size) {
    final curve = 26.0;
    final path = Path()..lineTo(0, size.height - curve);
    path.quadraticBezierTo(
      size.width * .50,
      size.height + curve,
      size.width,
      size.height - curve,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
