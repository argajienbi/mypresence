import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color color;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 22,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(radius),
        border:
            Border.all(color: Colors.white.withValues(alpha: .72), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class LayeredCurveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color layerColor;
  final Color color;
  final EdgeInsetsGeometry? margin;

  const LayeredCurveCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 28,
    this.layerColor = const Color(0xFFBFEFF7),
    this.color = Colors.white,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 10,
            right: -8,
            top: 12,
            bottom: -10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: layerColor.withValues(alpha: .72),
                borderRadius: BorderRadius.circular(radius + 2),
              ),
            ),
          ),
          Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .98),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                  color: Colors.white.withValues(alpha: .85), width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: .10),
                    blurRadius: 24,
                    offset: const Offset(0, 12)),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class NeumorphicSoftCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color background;

  const NeumorphicSoftCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = 30,
    this.background = const Color(0xFFEAF8FA),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                  color: Colors.white.withValues(alpha: .95),
                  blurRadius: 16,
                  offset: const Offset(-7, -7)),
              BoxShadow(
                  color: const Color(0xFF9FB7C3).withValues(alpha: .34),
                  blurRadius: 20,
                  offset: const Offset(8, 9)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class GradientAccentCard extends StatelessWidget {
  final Widget child;
  final Color accent;
  final Color soft;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const GradientAccentCard({
    super.key,
    required this.child,
    required this.accent,
    required this.soft,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, soft, accent.withValues(alpha: .10)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .86)),
            boxShadow: [
              BoxShadow(
                  color: accent.withValues(alpha: .12),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                  right: -22,
                  top: -20,
                  child: _AccentBubble(
                      color: accent.withValues(alpha: .11), size: 72)),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentBubble extends StatelessWidget {
  final Color color;
  final double size;
  const _AccentBubble({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}
