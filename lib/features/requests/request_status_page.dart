import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_session.dart';
import '../../core/models/request_status_item.dart';
import '../../services/request_status_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/sticky_curve_header.dart';

enum RequestStatusFilter {
  all,
  pending,
  approved,
  rejected,
}

class RequestStatusPage extends StatefulWidget {
  final AppSession session;

  const RequestStatusPage({super.key, required this.session});

  @override
  State<RequestStatusPage> createState() => _RequestStatusPageState();
}

class _RequestStatusPageState extends State<RequestStatusPage> {
  final RequestStatusService _service = RequestStatusService();
  bool _loading = true;
  List<RequestStatusItem> _items = [];
  RequestStatusFilter _filter = RequestStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _service.loadRequests(widget.session);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<RequestStatusItem> get _filteredItems {
    switch (_filter) {
      case RequestStatusFilter.pending:
        return _items.where((item) => item.status == 'pending').toList(growable: false);
      case RequestStatusFilter.approved:
        return _items.where((item) => item.status == 'approved').toList(growable: false);
      case RequestStatusFilter.rejected:
        return _items.where((item) => item.status == 'rejected').toList(growable: false);
      case RequestStatusFilter.all:
        return List<RequestStatusItem>.from(_items);
    }
  }

  int _count(RequestStatusFilter filter) {
    switch (filter) {
      case RequestStatusFilter.all:
        return _items.length;
      case RequestStatusFilter.pending:
        return _items.where((item) => item.status == 'pending').length;
      case RequestStatusFilter.approved:
        return _items.where((item) => item.status == 'approved').length;
      case RequestStatusFilter.rejected:
        return _items.where((item) => item.status == 'rejected').length;
    }
  }

  void _selectFilter(RequestStatusFilter filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StickyCurveHeader(
            title: 'Status Pengajuan',
            subtitle: 'Pantau izin, QR titip absen, dan koreksi presensi',
            icon: Icons.assignment_turned_in_rounded,
            height: 108,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
                children: [
                  _FilterBar(
                    current: _filter,
                    countOf: _count,
                    onChanged: _selectFilter,
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const AppCard(
                      child: Padding(
                        padding: EdgeInsets.all(22),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                    )
                  else if (filteredItems.isEmpty)
                    const AppCard(
                      child: Padding(
                        padding: EdgeInsets.all(22),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_rounded, color: AppColors.muted, size: 38),
                            SizedBox(height: 10),
                            Text(
                              'Belum ada pengajuan.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredItems.map(_RequestStatusCard.new),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final RequestStatusFilter current;
  final int Function(RequestStatusFilter filter) countOf;
  final ValueChanged<RequestStatusFilter> onChanged;

  const _FilterBar({
    required this.current,
    required this.countOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      _FilterChipData(RequestStatusFilter.all, 'Semua'),
      _FilterChipData(RequestStatusFilter.pending, 'Pending'),
      _FilterChipData(RequestStatusFilter.approved, 'Disetujui'),
      _FilterChipData(RequestStatusFilter.rejected, 'Ditolak'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final filter in filters)
          ChoiceChip(
            label: Text('${filter.label} (${countOf(filter.value)})'),
            selected: current == filter.value,
            onSelected: (_) => onChanged(filter.value),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w900,
              color: current == filter.value ? Colors.white : AppColors.text,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: current == filter.value ? AppColors.primary : AppColors.line,
            ),
          ),
      ],
    );
  }
}

class _FilterChipData {
  final RequestStatusFilter value;
  final String label;

  const _FilterChipData(this.value, this.label);
}

class _RequestStatusCard extends StatelessWidget {
  final RequestStatusItem item;

  const _RequestStatusCard(this.item);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_kindIcon(item.kind), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.kindLabel,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (item.contextLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.contextLabel,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoRow(label: 'Tanggal pengajuan', value: item.createdAtLabel),
            const SizedBox(height: 6),
            _InfoRow(label: 'Tanggal target', value: item.targetDateLabel.isEmpty ? '-' : item.targetDateLabel),
            if (item.hasNote) ...[
              const SizedBox(height: 6),
              _InfoRow(label: 'Keterangan', value: item.note),
            ],
            if (item.hasAdminNote) ...[
              const SizedBox(height: 6),
              _InfoRow(label: 'Catatan admin', value: item.adminNote),
            ],
            const SizedBox(height: 6),
            _InfoRow(
              label: item.evidenceLabel,
              value: item.hasEvidence ? '${item.evidenceLabel} tersedia' : '${item.evidenceLabel} belum tersedia',
            ),
            if (item.hasProcessedAt) ...[
              const SizedBox(height: 6),
              _InfoRow(label: 'Tanggal diproses', value: item.processedAtLabel),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _kindIcon(RequestStatusKind kind) {
    switch (kind) {
      case RequestStatusKind.leave:
        return Icons.event_note_rounded;
      case RequestStatusKind.qrTarget:
      case RequestStatusKind.qrHelper:
        return Icons.qr_code_2_rounded;
      case RequestStatusKind.correction:
        return Icons.edit_note_rounded;
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.green;
      case 'rejected':
        return AppColors.red;
      default:
        return AppColors.orange;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
