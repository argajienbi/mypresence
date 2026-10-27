import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/models/app_session.dart';
import '../../../widgets/app_page_header.dart';

/// Header Home: [AppPageHeader] dengan avatar bulat 56 + lonceng.
/// Bentuknya kini sama dengan semua halaman dalam (teal datar, tinggi
/// konten 108); yang beda hanya isinya (salam + nama + tanggal + avatar).
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
    final name = session.displayName.trim().isEmpty
        ? 'User'
        : session.displayName.trim();
    final greeting = _getGreeting();
    final photoUrl = _displayPhotoUrl(
      session.photoUrl.trim(),
      session.photoPath.trim(),
    );

    return AppPageHeader(
      eyebrow: '$greeting,',
      title: name,
      subtitle: date,
      leading: _ProfileAvatar(displayName: name, photoUrl: photoUrl),
      trailing: _NotificationButton(
        count: unreadNotifications,
        onPressed: onNotificationPressed,
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
  final String displayName;
  final String photoUrl;

  const _ProfileAvatar({required this.displayName, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.isNotEmpty;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .18),
        border: Border.all(
          color: Colors.white.withValues(alpha: .40),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _InitialAvatar(displayName: displayName),
              )
            : _InitialAvatar(displayName: displayName),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String displayName;

  const _InitialAvatar({required this.displayName});

  @override
  Widget build(BuildContext context) {
    final parts = displayName
        .trim()
        .split(' ')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    final initials = parts.isEmpty
        ? 'U'
        : parts.length == 1
            ? parts.first.characters.first.toUpperCase()
            : (parts.first.characters.first +
                    parts.last.characters.first)
                .toUpperCase();

    return Container(
      color: Colors.white.withValues(alpha: .18),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: .35),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: const Icon(
              Icons.notifications_rounded,
              color: Colors.white,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
