import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/announcement.dart';
import '../../core/models/app_session.dart';
import '../../core/utils.dart';
import '../../services/announcement_service.dart';
import '../../services/app_notification_service.dart';
import '../notifications/notifications_page.dart';
import '../../widgets/app_page_header.dart';

class AnnouncementsPage extends StatelessWidget {
  final AppSession session;

  const AnnouncementsPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final service = AnnouncementService();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Pengumuman',
            icon: Icons.campaign_rounded,
            showBack: true,
            extra: Row(
              children: [
                const _TabPill(label: 'Pengumuman', active: true),
                const SizedBox(width: 8),
                _NotificationTabPill(
                  session: session,
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) =>
                          NotificationsPage(session: session),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Announcement>>(
        stream: service.watchAnnouncements(session),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <Announcement>[];
          if (items.isEmpty) return const _EmptyAnnouncement();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _AnnouncementCard(
                item: item,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AnnouncementDetailPage(item: item)),
                  );
                },
              );
            },
          );
        },
            ),
          ),
        ],
      ),
    );
  }
}

class AnnouncementDetailPage extends StatelessWidget {
  final Announcement item;

  const AnnouncementDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Detail Pengumuman',
            subtitle: _metaLine(item),
            icon: Icons.campaign_rounded,
            showBack: true,
          ),
          Expanded(
            child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black.withValues(alpha: .06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TypeBadge(type: item.type),
                const SizedBox(height: 14),
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 22, height: 1.2, fontWeight: FontWeight.w900, color: AppColors.text),
                ),
                const SizedBox(height: 8),
                Text(
                  _metaLine(item),
                  style: const TextStyle(color: AppColors.muted, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(item.body, style: const TextStyle(height: 1.55, color: AppColors.text)),
              ],
            ),
          ),
        ],
            ),
          ),
          ],
        ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement item;
  final VoidCallback onTap;

  const _AnnouncementCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(item.type);
    final pinned =
        item.raw['pinned'] == true || item.raw['is_pinned'] == true;
    return Material(
      color: pinned
          ? AppColors.primary.withValues(alpha: .05)
          : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: pinned
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: .45),
                  )
                : Border(
                    left: BorderSide(color: color, width: 4),
                    top: BorderSide(
                        color: Colors.black.withValues(alpha: .06)),
                    right: BorderSide(
                        color: Colors.black.withValues(alpha: .06)),
                    bottom: BorderSide(
                        color: Colors.black.withValues(alpha: .06)),
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .12),
                child: Icon(Icons.campaign_rounded, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TypeBadge(type: item.type),
                        if (pinned) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.push_pin_rounded,
                                    size: 11, color: AppColors.primary),
                                SizedBox(width: 3),
                                Text(
                                  'Disematkan',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.text)),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  static Color _typeColor(String type) {
    final value = type.toLowerCase();
    if (value.contains('warning')) return AppColors.orange;
    if (value.contains('danger')) return AppColors.red;
    if (value.contains('success')) return AppColors.green;
    return AppColors.primary;
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(type),
        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  static String _label(String type) {
    final value = type.toLowerCase();
    if (value.contains('warning')) return 'Peringatan';
    if (value.contains('danger')) return 'Penting';
    if (value.contains('success')) return 'Info Sukses';
    return 'Informasi';
  }
}

class _EmptyAnnouncement extends StatelessWidget {
  const _EmptyAnnouncement();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined, size: 54, color: AppColors.muted),
            SizedBox(height: 12),
            Text('Belum ada pengumuman', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text)),
            SizedBox(height: 6),
            Text('Pengumuman dari perusahaan akan tampil di sini.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

/// Pil tab di atas header teal (mockup pengumuman): Pengumuman aktif (putih),
/// Notifikasi (transparan + badge coral jumlah belum dibaca).
class _TabPill extends StatelessWidget {
  final String label;
  final bool active;

  const _TabPill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.primary : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NotificationTabPill extends StatelessWidget {
  final AppSession session;
  final VoidCallback onTap;

  const _NotificationTabPill({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final service = AppNotificationService();
    return StreamBuilder(
      stream: service.watchFirestoreInbox(session),
      builder: (context, firestoreSnapshot) {
        return StreamBuilder(
          stream: service.watchRtdbFallback(session),
          builder: (context, rtdbSnapshot) {
            final merged = service.mergePersonalInbox(
              firestoreSnapshot.data ?? const [],
              rtdbSnapshot.data ?? const [],
            );
            final unread = merged.where((e) => !e.read).length;
            return InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Notifikasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (unread > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        constraints: const BoxConstraints(
                          minWidth: 19,
                          minHeight: 19,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

String _metaLine(Announcement item) {
  final ts = item.publishedAt != 0 ? item.publishedAt : item.createdAt;
  final date = ts > 0 ? AppDate.dayDate(_toDateTime(ts)) : '';
  final parts = [
    if (date.isNotEmpty) date,
    _TypeBadge._label(item.type),
  ];
  return parts.join(' • ');
}

DateTime _toDateTime(int value) {
  // Backend menyimpan epoch detik atau milidetik — tebak dari besarannya.
  if (value > 1000000000000) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return DateTime.fromMillisecondsSinceEpoch(value * 1000);
}
