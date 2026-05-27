import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_notification.dart';
import '../../core/models/app_session.dart';
import '../../services/app_notification_service.dart';
import 'notification_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  final AppSession session;

  const NotificationsPage({super.key, required this.session});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final AppNotificationService _service = AppNotificationService();
  bool _showUnreadOnly = false;
  bool _markingAll = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Notifikasi')),
      body: StreamBuilder<List<AppNotification>>(
        stream: _service.watchFirestoreInbox(widget.session),
        builder: (context, firestoreSnapshot) {
          final firestoreItems = firestoreSnapshot.data ?? const <AppNotification>[];
          return StreamBuilder<List<AppNotification>>(
            stream: _service.watchRtdbFallback(widget.session),
            builder: (context, rtdbSnapshot) {
              final rtdbItems = rtdbSnapshot.data ?? const <AppNotification>[];
              final merged = _service.mergeInbox(firestoreItems, rtdbItems);
              final unreadCount = merged.where((e) => !e.read).length;
              final items = _showUnreadOnly ? merged.where((e) => !e.read).toList() : merged;

              return Column(
                children: [
                  _NotificationToolbar(
                    unreadCount: unreadCount,
                    showUnreadOnly: _showUnreadOnly,
                    isMarkingAll: _markingAll,
                    onShowAll: () => setState(() => _showUnreadOnly = false),
                    onShowUnread: () => setState(() => _showUnreadOnly = true),
                    onMarkAll: unreadCount == 0
                        ? null
                        : () async {
                            setState(() => _markingAll = true);
                            try {
                              await _service.markAllAsRead(widget.session, merged);
                            } finally {
                              if (mounted) setState(() => _markingAll = false);
                            }
                          },
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? _EmptyNotification(unreadOnly: _showUnreadOnly)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _NotificationTile(
                                item: item,
                                onTap: () async {
                                  await _service.markAsRead(widget.session, item);
                                  if (!context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => NotificationDetailPage(
                                        session: widget.session,
                                        notification: item,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationToolbar extends StatelessWidget {
  final int unreadCount;
  final bool showUnreadOnly;
  final bool isMarkingAll;
  final VoidCallback onShowAll;
  final VoidCallback onShowUnread;
  final Future<void> Function()? onMarkAll;

  const _NotificationToolbar({
    required this.unreadCount,
    required this.showUnreadOnly,
    required this.isMarkingAll,
    required this.onShowAll,
    required this.onShowUnread,
    required this.onMarkAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: .05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            unreadCount > 0 ? '$unreadCount belum dibaca' : 'Semua notifikasi sudah dibaca',
            style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ToolbarChip(
                label: 'Semua',
                icon: Icons.check_rounded,
                selected: !showUnreadOnly,
                onTap: onShowAll,
              ),
              _ToolbarChip(
                label: 'Belum dibaca',
                icon: Icons.mark_email_unread_rounded,
                selected: showUnreadOnly,
                onTap: onShowUnread,
              ),
              _ToolbarChip(
                label: 'Tandai dibaca',
                icon: Icons.done_all_rounded,
                selected: false,
                enabled: unreadCount > 0 && !isMarkingAll && onMarkAll != null,
                loading: isMarkingAll,
                onTap: unreadCount > 0 && !isMarkingAll && onMarkAll != null ? () => onMarkAll!() : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolbarChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final bool loading;
  final VoidCallback? onTap;

  const _ToolbarChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary.withValues(alpha: .16) : Colors.white;
    final fg = selected ? AppColors.primary : AppColors.text;
    final border = selected ? AppColors.primary.withValues(alpha: .24) : AppColors.line;

    return Material(
      color: enabled ? bg : AppColors.line.withValues(alpha: .35),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: enabled ? border : AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Icon(icon, color: enabled ? fg : AppColors.muted, size: 19),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: enabled ? fg : AppColors.muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(item.type, item.refType);
    return Material(
      color: item.read ? Colors.white : color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: item.read ? AppColors.line : color.withValues(alpha: .30)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .12),
                child: Icon(_typeIcon(item.type, item.refType), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title.trim().isEmpty ? 'MYPRESENSI' : item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: item.read ? FontWeight.w700 : FontWeight.w900,
                              color: AppColors.text,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (!item.read) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.displayBody,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted, height: 1.35),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MiniMeta(icon: Icons.category_rounded, text: item.displayType),
                        _MiniMeta(icon: Icons.person_rounded, text: item.displaySender),
                        _MiniMeta(icon: Icons.schedule_rounded, text: _formatTime(item.createdAt)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  static Color _typeColor(String type, String refType) {
    final value = '$type $refType'.toLowerCase();
    if (value.contains('success') || value.contains('approved')) return AppColors.green;
    if (value.contains('warning') || value.contains('pending')) return AppColors.orange;
    if (value.contains('danger') || value.contains('error') || value.contains('rejected')) return AppColors.red;
    return AppColors.primary;
  }

  static IconData _typeIcon(String type, String refType) {
    final value = '$type $refType'.toLowerCase();
    if (value.contains('announcement')) return Icons.campaign_rounded;
    if (value.contains('success') || value.contains('approved')) return Icons.check_circle_rounded;
    if (value.contains('warning') || value.contains('pending')) return Icons.warning_rounded;
    if (value.contains('danger') || value.contains('error') || value.contains('rejected')) return Icons.error_rounded;
    if (value.contains('attendance') || value.contains('qr')) return Icons.fact_check_rounded;
    return Icons.notifications_rounded;
  }

  static String _formatTime(int timestamp) {
    if (timestamp <= 0) return 'Waktu tidak tersedia';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _MiniMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _EmptyNotification extends StatelessWidget {
  final bool unreadOnly;

  const _EmptyNotification({required this.unreadOnly});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_rounded, size: 54, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              unreadOnly ? 'Tidak ada notifikasi belum dibaca' : 'Belum ada notifikasi',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.text),
            ),
            const SizedBox(height: 6),
            Text(
              unreadOnly
                  ? 'Semua notifikasi yang masuk sudah ditandai dibaca.'
                  : 'Notifikasi dari perusahaan dan sistem presensi akan muncul di sini.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
