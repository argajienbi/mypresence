import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_notification.dart';
import '../../core/models/app_session.dart';
import '../../services/app_notification_service.dart';
import 'notification_detail_page.dart';

enum _NotificationFilter {
  all,
  unread,
  approval,
  schedule,
  correction,
  attendance,
  system
}

class NotificationsPage extends StatefulWidget {
  final AppSession session;

  const NotificationsPage({super.key, required this.session});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final AppNotificationService _service = AppNotificationService();
  final TextEditingController _searchController = TextEditingController();
  _NotificationFilter _filter = _NotificationFilter.all;
  bool _markingAll = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: StreamBuilder<List<AppNotification>>(
          stream: _service.watchFirestoreInbox(widget.session),
          builder: (context, firestoreSnapshot) {
            final firestoreItems =
                firestoreSnapshot.data ?? const <AppNotification>[];
            return StreamBuilder<List<AppNotification>>(
              stream: _service.watchRtdbFallback(widget.session),
              builder: (context, rtdbSnapshot) {
                final rtdbItems =
                    rtdbSnapshot.data ?? const <AppNotification>[];
                final merged =
                    _service.mergePersonalInbox(firestoreItems, rtdbItems);
                final unreadCount = merged.where((e) => !e.read).length;
                final filtered = _applyFilters(merged);
                final grouped = _groupNotifications(filtered);

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _NotificationHeader(
                                onBack: () => Navigator.of(context).pop()),
                            const SizedBox(height: 18),
                            _SearchField(
                              controller: _searchController,
                              onChanged: (value) =>
                                  setState(() => _query = value.trim()),
                            ),
                            const SizedBox(height: 14),
                            _SummaryCard(
                              unreadCount: unreadCount,
                              markingAll: _markingAll,
                              onMarkAll: unreadCount == 0
                                  ? null
                                  : () async {
                                      setState(() => _markingAll = true);
                                      try {
                                        await _service.markAllPersonalAsRead(
                                            widget.session, merged);
                                      } finally {
                                        if (mounted) {
                                          setState(() => _markingAll = false);
                                        }
                                      }
                                    },
                            ),
                            const SizedBox(height: 14),
                            _FilterChips(
                              selected: _filter,
                              totalCount: merged.length,
                              unreadCount: unreadCount,
                              onChanged: (filter) =>
                                  setState(() => _filter = filter),
                            ),
                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                    ),
                    if (filtered.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyNotification(
                          hasQuery: _query.isNotEmpty,
                          filter: _filter,
                        ),
                      )
                    else ...[
                      for (final section in grouped.entries) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                            child: Text(
                              section.key,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        SliverList.separated(
                          itemCount: section.value.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = section.value[index];
                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                18,
                                0,
                                18,
                                section.key == grouped.keys.last &&
                                        index == section.value.length - 1
                                    ? 32
                                    : 0,
                              ),
                              child: _NotificationTile(
                                item: item,
                                onTap: () async {
                                  await _service.markAsRead(
                                      widget.session, item);
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
                              ),
                            );
                          },
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<AppNotification> _applyFilters(List<AppNotification> source) {
    final query = _query.toLowerCase();
    return source.where((item) {
      if (_filter == _NotificationFilter.unread && item.read) return false;
      if (!_matchesFilter(item, _filter)) return false;
      if (query.isEmpty) return true;
      final searchText = [
        item.title,
        item.displayBody,
        item.displayType,
        item.displaySender,
        item.type,
        item.refType,
      ].join(' ').toLowerCase();
      return searchText.contains(query);
    }).toList();
  }

  bool _matchesFilter(AppNotification item, _NotificationFilter filter) {
    if (filter == _NotificationFilter.all ||
        filter == _NotificationFilter.unread) {
      return true;
    }
    final value =
        '${item.type} ${item.refType} ${item.title} ${item.displayBody}'
            .toLowerCase();
    switch (filter) {
      case _NotificationFilter.approval:
        return value.contains('approval') ||
            value.contains('approved') ||
            value.contains('rejected') ||
            value.contains('leave') ||
            value.contains('izin') ||
            value.contains('cuti') ||
            value.contains('sakit') ||
            value.contains('lembur');
      case _NotificationFilter.schedule:
        return value.contains('schedule') || value.contains('jadwal');
      case _NotificationFilter.correction:
        return value.contains('correction') || value.contains('koreksi');
      case _NotificationFilter.attendance:
        return value.contains('attendance') ||
            value.contains('presensi') ||
            value.contains('absensi') ||
            value.contains('qr');
      case _NotificationFilter.system:
        return value.contains('system') ||
            value.contains('sistem') ||
            value.contains('user_status') ||
            value.contains('status_update');
      case _NotificationFilter.all:
      case _NotificationFilter.unread:
        return true;
    }
  }

  Map<String, List<AppNotification>> _groupNotifications(
      List<AppNotification> items) {
    final now = DateTime.now();
    final today = <AppNotification>[];
    final previous = <AppNotification>[];

    for (final item in items) {
      if (_isSameDay(_dateFromNotification(item), now)) {
        today.add(item);
      } else {
        previous.add(item);
      }
    }

    return {
      if (today.isNotEmpty) 'Hari ini': today,
      if (previous.isNotEmpty) 'Sebelumnya': previous,
    };
  }

  DateTime _dateFromNotification(AppNotification item) {
    if (item.createdAt <= 0) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(item.createdAt);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _NotificationHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _NotificationHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          _CircleIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
          const Expanded(
            child: Center(
              child: Text(
                'Notifikasi',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.3,
                ),
              ),
            ),
          ),
          const _CircleIconButton(icon: Icons.tune_rounded),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .76),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.text, size: 25),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Cari notifikasi...',
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close_rounded, color: AppColors.muted),
              ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: .92),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              BorderSide(color: AppColors.primary.withValues(alpha: .10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              BorderSide(color: AppColors.primary.withValues(alpha: .10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: .35), width: 1.4),
        ),
      ),
      style:
          const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int unreadCount;
  final bool markingAll;
  final Future<void> Function()? onMarkAll;

  const _SummaryCard({
    required this.unreadCount,
    required this.markingAll,
    required this.onMarkAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: .10)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .07),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: .76),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.notifications_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unreadCount > 0
                      ? '$unreadCount belum dibaca'
                      : 'Semua sudah dibaca',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Notifikasi personal Anda',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed:
                onMarkAll == null || markingAll ? null : () => onMarkAll!(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.line,
              disabledForegroundColor: AppColors.muted,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: markingAll
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text(
                    'Tandai semua\ndibaca',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        height: 1.12),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final _NotificationFilter selected;
  final int totalCount;
  final int unreadCount;
  final ValueChanged<_NotificationFilter> onChanged;

  const _FilterChips({
    required this.selected,
    required this.totalCount,
    required this.unreadCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final chips = [
      _FilterChipData(
          _NotificationFilter.all, 'Semua', totalCount, Icons.done_rounded),
      _FilterChipData(_NotificationFilter.unread, 'Belum dibaca', unreadCount,
          Icons.mark_email_unread_rounded),
      _FilterChipData(_NotificationFilter.approval, 'Approval', null,
          Icons.verified_rounded),
      _FilterChipData(_NotificationFilter.schedule, 'Jadwal', null,
          Icons.calendar_month_rounded),
      _FilterChipData(_NotificationFilter.correction, 'Koreksi', null,
          Icons.edit_note_rounded),
      _FilterChipData(_NotificationFilter.attendance, 'Presensi', null,
          Icons.fact_check_rounded),
      _FilterChipData(
          _NotificationFilter.system, 'Sistem', null, Icons.settings_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final chip in chips) ...[
            _FilterChip(
              data: chip,
              selected: selected == chip.filter,
              onTap: () => onChanged(chip.filter),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChipData {
  final _NotificationFilter filter;
  final String label;
  final int? count;
  final IconData icon;

  const _FilterChipData(this.filter, this.label, this.count, this.icon);
}

class _FilterChip extends StatelessWidget {
  final _FilterChipData data;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.data, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg =
        selected ? AppColors.primary : Colors.white.withValues(alpha: .88);
    final fg = selected ? Colors.white : AppColors.text;
    final border =
        selected ? AppColors.primary : AppColors.primary.withValues(alpha: .10);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, size: 17, color: fg),
              const SizedBox(width: 7),
              Text(
                data.count == null ? data.label : '${data.label} ${data.count}',
                style: TextStyle(
                    color: fg, fontSize: 12.5, fontWeight: FontWeight.w900),
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
    final category = _NotificationCategory.from(item);
    final unread = !item.read;

    return Material(
      color: unread ? category.color.withValues(alpha: .08) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: unread
                  ? category.color.withValues(alpha: .28)
                  : AppColors.line,
              width: unread ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .035),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: category.color.withValues(alpha: .12),
                    ),
                    child: Icon(category.icon, color: category.color, size: 28),
                  ),
                  if (unread)
                    Positioned(
                      right: 1,
                      top: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: category.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title.trim().isEmpty
                                ? 'MYPRESENSI'
                                : item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 15.5,
                              fontWeight:
                                  unread ? FontWeight.w900 : FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: 5),
                              decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.displayBody,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.38,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 9,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MiniMeta(
                            icon: category.metaIcon,
                            text: category.label,
                            color: category.color),
                        _MiniMeta(
                            icon: Icons.person_rounded,
                            text: item.displaySender),
                        _MiniMeta(
                            icon: Icons.schedule_rounded,
                            text: _formatShortTime(item.createdAt)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.muted, size: 26),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatShortTime(int timestamp) {
    if (timestamp <= 0) return '--:--';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return time;
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}

class _NotificationCategory {
  final String label;
  final IconData icon;
  final IconData metaIcon;
  final Color color;

  const _NotificationCategory({
    required this.label,
    required this.icon,
    required this.metaIcon,
    required this.color,
  });

  factory _NotificationCategory.from(AppNotification item) {
    final value =
        '${item.type} ${item.refType} ${item.title} ${item.displayBody}'
            .toLowerCase();
    if (value.contains('correction') || value.contains('koreksi')) {
      return const _NotificationCategory(
          label: 'Koreksi',
          icon: Icons.edit_note_rounded,
          metaIcon: Icons.edit_rounded,
          color: AppColors.orange);
    }
    if (value.contains('schedule') || value.contains('jadwal')) {
      return const _NotificationCategory(
          label: 'Jadwal',
          icon: Icons.calendar_month_rounded,
          metaIcon: Icons.calendar_month_rounded,
          color: AppColors.blue);
    }
    if (value.contains('qr')) {
      return const _NotificationCategory(
          label: 'QR',
          icon: Icons.qr_code_2_rounded,
          metaIcon: Icons.qr_code_2_rounded,
          color: AppColors.purple);
    }
    if (value.contains('attendance') ||
        value.contains('presensi') ||
        value.contains('absensi')) {
      return const _NotificationCategory(
          label: 'Presensi',
          icon: Icons.fact_check_rounded,
          metaIcon: Icons.fact_check_rounded,
          color: AppColors.purple);
    }
    if (value.contains('system') ||
        value.contains('sistem') ||
        value.contains('status_update') ||
        value.contains('user_status')) {
      return const _NotificationCategory(
          label: 'Sistem',
          icon: Icons.settings_rounded,
          metaIcon: Icons.settings_rounded,
          color: AppColors.muted);
    }
    if (value.contains('warning') ||
        value.contains('pending') ||
        value.contains('lembur')) {
      return const _NotificationCategory(
          label: 'Approval',
          icon: Icons.pending_actions_rounded,
          metaIcon: Icons.verified_user_rounded,
          color: AppColors.orange);
    }
    if (value.contains('danger') ||
        value.contains('error') ||
        value.contains('rejected') ||
        value.contains('ditolak')) {
      return const _NotificationCategory(
          label: 'Approval',
          icon: Icons.error_rounded,
          metaIcon: Icons.verified_user_rounded,
          color: AppColors.red);
    }
    return const _NotificationCategory(
        label: 'Approval',
        icon: Icons.check_circle_rounded,
        metaIcon: Icons.verified_user_rounded,
        color: AppColors.green);
  }
}

class _MiniMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _MiniMeta({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? AppColors.muted),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color ?? AppColors.muted,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyNotification extends StatelessWidget {
  final bool hasQuery;
  final _NotificationFilter filter;

  const _EmptyNotification({required this.hasQuery, required this.filter});

  @override
  Widget build(BuildContext context) {
    final title = hasQuery
        ? 'Notifikasi tidak ditemukan'
        : filter == _NotificationFilter.unread
            ? 'Tidak ada notifikasi belum dibaca'
            : 'Belum ada notifikasi personal';
    final body = hasQuery
        ? 'Coba gunakan kata kunci lain.'
        : filter == _NotificationFilter.unread
            ? 'Semua notifikasi personal Anda sudah dibaca.'
            : 'Approval, perubahan jadwal, status presensi, dan informasi sistem personal akan muncul di sini.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: .10),
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 42, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
