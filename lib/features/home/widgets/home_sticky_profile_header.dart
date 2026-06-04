import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/models/app_session.dart';
import '../../../core/utils.dart';

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
      height: 178,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF04B96E), Color(0xFF0796B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            left: -40,
            right: -40,
            bottom: -42,
            child: Container(
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 22,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: .20),
                      Colors.white.withValues(alpha: .08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: .34)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .14),
                      blurRadius: 24,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _ProfileAvatar(firstName: firstName, photoUrl: photoUrl),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting, $firstName',
                            style: const TextStyle(
                              fontSize: 19,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text.withValues(alpha: .72),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _NotificationButton(
                      count: unreadNotifications,
                      onPressed: onNotificationPressed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String firstName;
  final String photoUrl;

  const _ProfileAvatar({required this.firstName, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.isNotEmpty;

    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .82),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _InitialAvatar(firstName: firstName),
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
    final initial = firstName.trim().isEmpty ? 'U' : firstName.characters.first.toUpperCase();

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: .30),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w900,
          color: Colors.white,
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
        Material(
          color: Colors.white.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: const SizedBox(
              width: 50,
              height: 50,
              child: Icon(Icons.notifications_rounded, color: AppColors.text, size: 28),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            right: -2,
            top: -3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
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
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
