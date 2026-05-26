import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/announcement.dart';
import '../../core/models/app_session.dart';
import '../../services/announcement_service.dart';

class AnnouncementsPage extends StatelessWidget {
  final AppSession session;

  const AnnouncementsPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final service = AnnouncementService();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Pengumuman')),
      body: StreamBuilder<List<Announcement>>(
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
      appBar: AppBar(title: const Text('Detail Pengumuman')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
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
                const SizedBox(height: 12),
                Text(item.body, style: const TextStyle(height: 1.55, color: AppColors.text)),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: .06)),
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
                    _TypeBadge(type: item.type),
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
