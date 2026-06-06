import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/models/app_session.dart';

class HomeStickyProfileHeader extends StatelessWidget {
  final AppSession session;
  final String date;
  final int unreadNotifications;
  final VoidCallback onNotificationPressed;

  const HomeStickyProfileHeader({
    super.key,
    required this.session,
    required this.date,
    this.unreadNotifications = 0,
    required this.onNotificationPressed,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'Selamat pagi';
    if (hour >= 11 && hour < 15) return 'Selamat siang';
    if (hour >= 15 && hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = session.displayName
            .trim()
            .split(' ')
            .where((e) => e.isNotEmpty)
            .firstOrNull ??
        'User';
    final greeting = _getGreeting();
    final photoUrl = session.photoUrl.trim();

    return SizedBox(
      height: 184,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _HeaderPainter(),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ProfileAvatar(firstName: firstName, photoUrl: photoUrl),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, $firstName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 20,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.text.withValues(alpha: .82),
                            fontSize: 14,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _NotificationButton(
                    count: unreadNotifications,
                    onPressed: onNotificationPressed,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderPainter extends CustomPainter {
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProfileAvatar extends StatelessWidget {
  final String firstName;
  final String photoUrl;

  const _ProfileAvatar({required this.firstName, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.isNotEmpty;

    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _InitialAvatar(firstName: firstName),
              )
            : _InitialAvatar(firstName: firstName),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String firstName;

  const _InitialAvatar({required this.firstName});

  @override
  Widget build(BuildContext context) {
    final initial = firstName.trim().isEmpty
        ? 'U'
        : firstName.characters.first.toUpperCase();

    return Container(
      color: AppColors.primary.withValues(alpha: .32),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _NotificationButton({required this.count, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: const Icon(
            Icons.notifications_rounded,
            color: Colors.white,
            size: 34,
          ),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
        ),
        if (count > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 23, minHeight: 23),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
