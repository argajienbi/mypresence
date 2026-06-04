import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/models/announcement.dart';
import '../../../core/models/app_session.dart';
import '../../../services/announcement_service.dart';
import '../../../widgets/app_card.dart';
import '../../announcements/announcements_page.dart';

class HomeAnnouncementCard extends StatefulWidget {
  final AppSession session;

  const HomeAnnouncementCard({
    super.key,
    required this.session,
  });

  @override
  State<HomeAnnouncementCard> createState() => _HomeAnnouncementCardState();
}

class _HomeAnnouncementCardState extends State<HomeAnnouncementCard> {
  bool _isExpanded = true;

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
      case 'caution':
        return AppColors.orange;
      case 'danger':
      case 'error':
        return AppColors.red;
      case 'success':
        return AppColors.green;
      case 'info':
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
      case 'caution':
        return Icons.warning_rounded;
      case 'danger':
      case 'error':
        return Icons.error_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      case 'info':
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = AnnouncementService();

    return StreamBuilder<List<Announcement>>(
      stream: service.watchAnnouncements(widget.session),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <Announcement>[];
        final hasAnnouncements = items.isNotEmpty;
        final displayItems = items.take(2).toList();

        return AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() => _isExpanded = !_isExpanded);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pengumuman',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.text,
                                ),
                              ),
                              if (!hasAnnouncements)
                                const Text(
                                  'Belum ada pengumuman terbaru',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: _isExpanded ? 0 : 0.5,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.expand_less_rounded,
                              color: AppColors.muted, size: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              if (_isExpanded && hasAnnouncements) ...[
                Container(height: 1, color: AppColors.line),
                ...List.generate(
                  displayItems.length,
                  (index) {
                    final item = displayItems[index];
                    final isLast = index == displayItems.length - 1;

                    return Column(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AnnouncementDetailPage(item: item),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _getTypeColor(item.type)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _getTypeIcon(item.type),
                                        color: _getTypeColor(item.type),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.text,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.body,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.muted,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded,
                                      color: AppColors.muted, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!isLast)
                          Container(height: 1, color: AppColors.line),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
