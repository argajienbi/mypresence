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
                      radius: 10,
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
                      radius: 10,
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
      _TypeChipData(RequestTypeFilter.all, 'Semua'),
      _TypeChipData(RequestTypeFilter.izin, 'Izin'),
      _TypeChipData(RequestTypeFilter.sakit, 'Sakit'),
      _TypeChipData(RequestTypeFilter.cuti, 'Cuti'),
      _TypeChipData(RequestTypeFilter.lembur, 'Lembur'),
      _TypeChipData(RequestTypeFilter.qr, 'QR'),
      _TypeChipData(RequestTypeFilter.correction, 'Koreksi'),
    ];

    const labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: AppColors.muted,
      letterSpacing: .5,
    );

    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STATUS', style: labelStyle),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                for (final filter in filters)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(filter.value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: current == filter.value
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${filter.label} (${countOf(filter.value)})',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: current == filter.value
                                ? Colors.white
                                : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('JENIS PENGAJUAN', style: labelStyle),
          const SizedBox(height: 8),
          Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var index = 0; index < types.length; index++) ...[
                      GestureDetector(
                        onTap: () => onTypeChanged(types[index].value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: currentType == types[index].value
                                ? AppColors.primary
                                : AppColors.bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            types[index].label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: currentType == types[index].value
                                  ? Colors.white
                                  : AppColors.text,
                            ),
                          ),
                        ),
                      ),
                      if (index != types.length - 1)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
    final stubLabel = _stubLabel(item.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              showRequestStatusDetailSheet(context: context, item: item),
          borderRadius: BorderRadius.circular(10),
          child: AppCard(
            padding: EdgeInsets.zero,
            radius: 10,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(_kindIcon(item.kind),
                                color: color, size: 24),
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.createdAtLabel} • ${item.targetDateLabel.isEmpty ? '-' : item.targetDateLabel}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (item.hasNote) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.note,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: const _DashedLinePainter(),
                    child: const SizedBox(width: 2),
                  ),
                  ClipPath(
                    clipper: _SlantClipper(),
                    child: Container(
                      width: 96,
                      color: color.withValues(alpha: .14),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        stubLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: color,
                          letterSpacing: .5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _stubLabel(String status) {
    switch (status) {
      case 'approved':
        return 'DISETUJUI';
      case 'rejected':
        return 'DITOLAK';
      default:
        return 'PENDING';
    }
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

class _SlantClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width * .2, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant _SlantClipper oldClipper) => false;
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1.5;
    const dashHeight = 4.0;
    const dashGap = 3.0;
    double y = 8;
    while (y < size.height - 8) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + dashHeight),
        paint,
      );
      y += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}
