import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_session.dart';
import '../../core/models/request_status_item.dart';
import '../../services/request_status_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/sticky_curve_header.dart';
import 'request_status_detail_sheet.dart';

enum RequestStatusFilter {
  all,
  pending,
  approved,
  rejected,
}

enum RequestTypeFilter {
  all,
  izin,
  sakit,
  cuti,
  lembur,
  qr,
  correction,
}

class RequestStatusPage extends StatefulWidget {
  final AppSession session;
  final RequestStatusFilter? initialStatus;
  final RequestTypeFilter? initialType;
  final String? highlightRefId;

  const RequestStatusPage({
    super.key,
    required this.session,
    this.initialStatus,
    this.initialType,
    this.highlightRefId,
  });

  @override
  State<RequestStatusPage> createState() => _RequestStatusPageState();
}

class _RequestStatusPageState extends State<RequestStatusPage> {
  final RequestStatusService _service = RequestStatusService();
  bool _loading = true;
  List<RequestStatusItem> _items = [];
  late RequestStatusFilter _filter;
  late RequestTypeFilter _typeFilter;
  bool _openedHighlightDetail = false;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialStatus ?? RequestStatusFilter.all;
    _typeFilter = widget.initialType ?? RequestTypeFilter.all;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _service.loadRequests(widget.session);
      if (!mounted) return;
      setState(() => _items = items);
      _maybeOpenHighlightedDetail();
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _maybeOpenHighlightedDetail() {
    final refId = widget.highlightRefId?.trim() ?? '';
    if (refId.isEmpty || _openedHighlightDetail) return;

    RequestStatusItem? match;
    for (final item in _items) {
      if (item.id == refId) {
        match = item;
        break;
      }
    }

    if (match == null) return;
    _openedHighlightDetail = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showRequestStatusDetailSheet(context: context, item: match!);
    });
  }

  List<RequestStatusItem> get _filteredItems {
    return _items.where((item) {
      final statusMatch = switch (_filter) {
        RequestStatusFilter.pending => item.status == 'pending',
        RequestStatusFilter.approved => item.status == 'approved',
        RequestStatusFilter.rejected => item.status == 'rejected',
        RequestStatusFilter.all => true,
      };
      final typeMatch = switch (_typeFilter) {
        RequestTypeFilter.all => true,
        RequestTypeFilter.izin => item.isLeave && item.typeKey == 'izin',
        RequestTypeFilter.sakit => item.isLeave && item.typeKey == 'sakit',
        RequestTypeFilter.cuti => item.isLeave && item.typeKey == 'cuti',
        RequestTypeFilter.lembur => item.isLeave && item.typeKey == 'lembur',
        RequestTypeFilter.qr => item.isQr,
        RequestTypeFilter.correction => item.isCorrection,
      };
      return statusMatch && typeMatch;
    }).toList(growable: false);
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

  void _selectTypeFilter(RequestTypeFilter filter) {
    if (_typeFilter == filter) return;
    setState(() => _typeFilter = filter);
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;
    final emptyMessage = _items.isEmpty
        ? 'Belum ada pengajuan.'
        : 'Tidak ada pengajuan yang cocok dengan filter saat ini.';

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
                    currentType: _typeFilter,
                    countOf: _count,
                    onChanged: _selectFilter,
                    onTypeChanged: _selectTypeFilter,
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const AppCard(
                      child: Padding(
                        padding: EdgeInsets.all(22),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      ),
                    )
                  else if (filteredItems.isEmpty)
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            const Icon(Icons.inbox_rounded,
                                color: AppColors.muted, size: 38),
                            const SizedBox(height: 10),
                            Text(
                              emptyMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
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
  final RequestTypeFilter currentType;
  final int Function(RequestStatusFilter filter) countOf;
  final ValueChanged<RequestStatusFilter> onChanged;
  final ValueChanged<RequestTypeFilter> onTypeChanged;

  const _FilterBar({
    required this.current,
    required this.currentType,
    required this.countOf,
    required this.onChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      _FilterChipData(RequestStatusFilter.all, 'Semua'),
      _FilterChipData(RequestStatusFilter.pending, 'Pending'),
      _FilterChipData(RequestStatusFilter.approved, 'Disetujui'),
      _FilterChipData(RequestStatusFilter.rejected, 'Ditolak'),
    ];

    final types = [
      _TypeChipData(RequestTypeFilter.all, 'Semua Jenis'),
      _TypeChipData(RequestTypeFilter.izin, 'Izin'),
      _TypeChipData(RequestTypeFilter.sakit, 'Sakit'),
      _TypeChipData(RequestTypeFilter.cuti, 'Cuti'),
      _TypeChipData(RequestTypeFilter.lembur, 'Lembur'),
      _TypeChipData(RequestTypeFilter.qr, 'QR'),
      _TypeChipData(RequestTypeFilter.correction, 'Koreksi'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
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
                  color:
                      current == filter.value ? Colors.white : AppColors.text,
                ),
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: current == filter.value
                      ? AppColors.primary
                      : AppColors.line,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < types.length; index++) ...[
                ChoiceChip(
                  label: Text(types[index].label),
                  selected: currentType == types[index].value,
                  onSelected: (_) => onTypeChanged(types[index].value),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: currentType == types[index].value
                        ? Colors.white
                        : AppColors.text,
                  ),
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: currentType == types[index].value
                        ? AppColors.primary
                        : AppColors.line,
                  ),
                ),
                if (index != types.length - 1) const SizedBox(width: 10),
              ],
            ],
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

class _TypeChipData {
  final RequestTypeFilter value;
  final String label;

  const _TypeChipData(this.value, this.label);
}

class _RequestStatusCard extends StatelessWidget {
  final RequestStatusItem item;

  const _RequestStatusCard(this.item);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              showRequestStatusDetailSheet(context: context, item: item),
          borderRadius: BorderRadius.circular(24),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 6),
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
                _InfoRow(
                    label: 'Tanggal pengajuan', value: item.createdAtLabel),
                const SizedBox(height: 6),
                _InfoRow(
                    label: 'Tanggal target',
                    value: item.targetDateLabel.isEmpty
                        ? '-'
                        : item.targetDateLabel),
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
                  value: item.hasEvidence
                      ? '${item.evidenceLabel} tersedia'
                      : '${item.evidenceLabel} belum tersedia',
                ),
                if (item.hasProcessedAt) ...[
                  const SizedBox(height: 6),
                  _InfoRow(
                      label: 'Tanggal diproses', value: item.processedAtLabel),
                ],
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Tap untuk detail',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
