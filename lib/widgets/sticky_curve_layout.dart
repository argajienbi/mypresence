import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'soft_header.dart';

class StickyCurvePage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final Widget overlapChild;
  final List<Widget> children;
  final double headerHeight;
  final double overlapTop;
  final double bottomPadding;

  const StickyCurvePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.overlapChild,
    required this.children,
    this.trailing,
    this.headerHeight = 205,
    this.overlapTop = 132,
    this.bottomPadding = 112,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SoftHeaderBackground(height: headerHeight),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 26, 18, 0),
            child: SourcePageTitle(
              title: title,
              subtitle: subtitle,
              icon: icon,
              trailing: trailing,
            ),
          ),
        ),
        Positioned.fill(
          top: overlapTop,
          child: ListView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(18, 0, 18, bottomPadding),
            children: [
              overlapChild,
              const SizedBox(height: 18),
              ...children,
            ],
          ),
        ),
      ],
    );
  }
}

class SourceRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const SourceRoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .78),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: color ?? AppColors.text, size: 21),
        ),
      ),
    );
  }
}
