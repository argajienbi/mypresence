import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_session.dart';
import '../../core/models/request_status_item.dart';
import '../../services/request_status_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_page_header.dart';
import '../corrections/attendance_correction_form_page.dart';
import '../leave/leave_form_page.dart';
import '../proxy_qr/proxy_attendance_page.dart';
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

  Future<void> _openLeaveForm() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            LeaveFormPage(session: widget.session, type: 'izin'),
      ),
    );
    if (submitted == true && mounted) _load();
  }

  Future<void> _openCorrectionForm() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AttendanceCorrectionFormPage(
          session: widget.session,
          initialDate: DateTime.now(),
          oldAttendance: null,
        ),
      ),
    );
    if (submitted == true && mounted) _load();
  }

  Future<void> _openProxyQr() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProxyAttendancePage(session: widget.session),
      ),
    );
    if (submitted == true && mounted) _load();
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
          AppPageHeader(
            title: 'Pengajuan',
            subtitle: 'Pantau izin, QR titip absen, dan koreksi presensi',
            icon: Icons.assignment_turned_in_outlined,
            showBack: true,
            trailing: InkWell(
              onTap: _openLeaveForm,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .35),
                  ),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
                children: [
                  _StatsRow(
                    pending: _count(RequestStatusFilter.pending),
                    approved: _count(RequestStatusFilter.approved),
                    rejected: _count(RequestStatusFilter.rejected),
                    current: _filter,
                    onSelect: _selectFilter,
                  ),
                  const SizedBox(height: 12),
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
                  if (!_loading) ...[
                    const SizedBox(height: 16),
                    _LinkRow(
                      icon: Icons.edit_note_rounded,
                      label: 'Koreksi Absensi',
                      onTap: _openCorrectionForm,
                    ),
                    const SizedBox(height: 10),
                    _LinkRow(
                      icon: Icons.qr_code_2_rounded,
                      label: 'Titip Absen QR',
                      onTap: _openProxyQr,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu ringkasan hitungan (mockup pengajuan). Ketuk kartu untuk memfilter.
class _StatsRow extends StatelessWidget {
  final int pending;
  final int approved;
  final int rejected;
  final RequestStatusFilter current;
  final ValueChanged<RequestStatusFilter> onSelect;

  const _StatsRow({
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          label: 'Menunggu',
          count: pending,
          color: AppColors.orange,
          selected: current == RequestStatusFilter.pending,
          onTap: () => onSelect(RequestStatusFilter.pending),
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Disetujui',
          count: approved,
          color: AppColors.green,
          selected: current == RequestStatusFilter.approved,
          onTap: () => onSelect(RequestStatusFilter.approved),
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Ditolak',
          count: rejected,
          color: AppColors.red,
          selected: current == RequestStatusFilter.rejected,
          onTap: () => onSelect(RequestStatusFilter.rejected),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : AppColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris tautan ke form koreksi / titip absen QR (mockup pengajuan).
class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
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
      _FilterChipData(RequestStatusFilter.pending, 'Menunggu'),
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
                                ? AppColors.primaryDark
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
        return 'MENUNGGU';
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
