import 'package:flutter/material.dart';
class CollapsingWavePage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget pinnedChild;
  final List<Widget> children;
  final Widget? trailing;
  final double expandedHeight;
  final double collapsedHeight;
  final double bottomPadding;
  final double bodyTopPadding;

  const CollapsingWavePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.pinnedChild,
    required this.children,
    this.trailing,
    this.expandedHeight = 360,
    this.collapsedHeight = 184,
    this.bottomPadding = 112,
    this.bodyTopPadding = 18,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _CollapsingWaveDelegate(
            title: title,
            subtitle: subtitle,
            icon: icon,
            trailing: trailing,
            pinnedChild: pinnedChild,
            expandedHeight: expandedHeight,
            collapsedHeight: collapsedHeight,
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(18, bodyTopPadding, 18, bottomPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              ...children,
            ]),
          ),
        ),
      ],
    );
  }
}

class _CollapsingWaveDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final Widget pinnedChild;
  final double expandedHeight;
  final double collapsedHeight;

  _CollapsingWaveDelegate({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
    required this.pinnedChild,
    required this.expandedHeight,
    required this.collapsedHeight,
  });

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final safeTop = MediaQuery.of(context).padding.top;
    final range = (maxExtent - minExtent).clamp(1.0, double.infinity);
    final t = (shrinkOffset / range).clamp(0.0, 1.0);
    final greetingOpacity = (1 - (t * 1.35)).clamp(0.0, 1.0);
    // The pinned card is intentionally moved upward while the header fades.
    // In the collapsed state it occupies the top visual area and replaces
    // the greeting/header, while the sliver extent still reserves enough
    // vertical space so the next content is never hidden behind the card.
    final cardTop = lerpDouble(104 + safeTop, 18 + safeTop, t);
    final horizontal = lerpDouble(18, 14, t);

    return Material(
      color: const Color(0xFFEFF8F6),
      elevation: overlapsContent ? 3 : 0,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            bottom: 54,
            child: ClipPath(
              clipper: _WaveClipper(progress: t),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF13A456), Color(0xFF0E8FA3)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(left: -55, top: safeTop - 70, child: _Bubble(size: 145, color: Colors.white.withValues(alpha: .22))),
          Positioned(right: -42, top: safeTop + 10, child: _Bubble(size: 118, color: Colors.white.withValues(alpha: .16))),
          Positioned(
            top: safeTop + 20 - (t * 18),
            left: 18,
            right: 18,
            child: Opacity(
              opacity: greetingOpacity,
              child: Transform.translate(
                offset: Offset(0, -24 * t),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), borderRadius: BorderRadius.circular(18)),
                      child: Icon(icon, color: const Color(0xFF0E9F6E)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 24, height: 1.05, fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 5),
                          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white)),
                        ],
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: cardTop,
            left: horizontal,
            right: horizontal,
            child: Transform.scale(
              alignment: Alignment.topCenter,
              scale: lerpDouble(1, .97, t),
              child: pinnedChild,
            ),
          ),
        ],
      ),
    );
  }

  double lerpDouble(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRebuild(covariant _CollapsingWaveDelegate oldDelegate) {
    return title != oldDelegate.title || subtitle != oldDelegate.subtitle || pinnedChild != oldDelegate.pinnedChild || trailing != oldDelegate.trailing || expandedHeight != oldDelegate.expandedHeight || collapsedHeight != oldDelegate.collapsedHeight;
  }
}

class _WaveClipper extends CustomClipper<Path> {
  final double progress;
  const _WaveClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final wave = 34 - (progress * 14);
    final path = Path()..lineTo(0, size.height - wave);
    path.quadraticBezierTo(size.width * .26, size.height + wave, size.width * .55, size.height - wave * .25);
    path.quadraticBezierTo(size.width * .78, size.height - wave * 1.35, size.width, size.height - wave * .35);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _WaveClipper oldClipper) => oldClipper.progress != progress;
}

class _Bubble extends StatelessWidget {
  final double size;
  final Color color;
  const _Bubble({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
