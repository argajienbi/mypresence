import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class SoftHeaderBackground extends StatelessWidget {
  final double height;
  final bool deepCurve;

  const SoftHeaderBackground({
    super.key,
    this.height = 205,
    this.deepCurve = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: ClipPath(
        clipper: _SourceHeaderClipper(deepCurve: deepCurve),
        child: Container(
          height: height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFD9F6FA), Color(0xFFE6F8FF), Color(0xFFD8ECFF)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                top: 18,
                left: 24,
                child: _HeaderRing(size: 34, opacity: .20),
              ),
              const Positioned(
                top: -38,
                right: -28,
                child: _HeaderRing(size: 148, opacity: .22),
              ),
              const Positioned(
                right: 26,
                bottom: 44,
                child: _HeaderRing(size: 54, opacity: .18),
              ),
              Positioned(
                left: -54,
                bottom: -48,
                child: Container(
                  width: 154,
                  height: 154,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: .08),
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

class _HeaderRing extends StatelessWidget {
  final double size;
  final double opacity;

  const _HeaderRing({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
        border: Border.all(color: Colors.white.withValues(alpha: .34), width: 1.1),
      ),
    );
  }
}

class _SourceHeaderClipper extends CustomClipper<Path> {
  final bool deepCurve;

  const _SourceHeaderClipper({required this.deepCurve});

  @override
  Path getClip(Size size) {
    final y = deepCurve ? .73 : .82;
    return Path()
      ..lineTo(0, size.height * y)
      ..cubicTo(
        size.width * .20,
        size.height * (deepCurve ? .99 : .95),
        size.width * .70,
        size.height * (deepCurve ? .89 : .88),
        size.width,
        size.height * (deepCurve ? .67 : .77),
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant _SourceHeaderClipper oldClipper) => oldClipper.deepCurve != deepCurve;
}

class HeaderScaffold extends StatelessWidget {
  final Widget child;
  final double headerHeight;

  const HeaderScaffold({
    super.key,
    required this.child,
    this.headerHeight = 205,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SoftHeaderBackground(height: headerHeight),
        SafeArea(child: child),
      ],
    );
  }
}

class SourcePageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  const SourcePageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .74),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 24, height: 1.05, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -.4)),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(subtitle!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
