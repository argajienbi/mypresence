import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/models/app_session.dart';

/// Header Home gaya BRIMO: gradient biru, teks putih.
/// Seluruh logika (salam, avatar, foto, badge notifikasi) dipertahankan.
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
    final photoUrl = _displayPhotoUrl(
      session.photoUrl.trim(),
      session.photoPath.trim(),
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .85),
                        fontSize: 13,
                        height: 1.05,
                        fontWeight: FontWeight.w600,
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
    );
  }
}

String _displayPhotoUrl(String photoUrl, String photoPath) {
  if (photoUrl.trim().isEmpty) return '';
  final cacheKey =
      photoPath.trim().isEmpty ? photoUrl.trim() : photoPath.trim();
  final separator = photoUrl.contains('?') ? '&' : '?';
  return '${photoUrl.trim()}${separator}v=${Uri.encodeComponent(cacheKey)}';
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 16,
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
    final initial = firstName.trim().isEmpty
        ? 'U'
        : firstName.characters.first.toUpperCase();

    return Container(
      color: AppColors.primary,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: const Icon(
              Icons.notifications_rounded,
              color: Colors.white,
              size: 26,
            ),
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.accent,
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
