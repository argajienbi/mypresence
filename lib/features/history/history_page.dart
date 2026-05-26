import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_session.dart';
import '../../core/utils.dart';
import '../../services/attendance_service.dart';
import '../../services/leave_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/sticky_curve_header.dart';

class HistoryPage extends StatefulWidget {
  final AppSession session;

  const HistoryPage({super.key, required this.session});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final AttendanceService _attendance = AttendanceService();
  final LeaveService _leave = LeaveService();

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _leaveRows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _attendance.getMonthlyHistory(session: widget.session, month: _month);
      final leaves = await _leave.getMonthlyRequests(session: widget.session, month: _month);
      if (!mounted) return;
      setState(() {
        _rows = data;
        _leaveRows = leaves;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rows = [];
        _leaveRows = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _load();
  }

  _MonthSummary _summary() {
    int hadir = 0;
    int telat = 0;
    int alpha = 0;
    final datesByKey = <String, List<String>>{
      'hadir': [],
      'telat': [],
      'izin': [],
      'sakit': [],
      'cuti': [],
      'alpha': [],
    };

    for (final row in _rows) {
      final date = (row['date'] ?? '').toString();
      final masuk = row['masuk'];
      final pulang = row['pulang'];
      final hasMasuk = masuk is Map;
      final hasPulang = pulang is Map;
      final explicit = _rowStatus(row);
      if (hasMasuk || hasPulang) {
        hadir++;
        if (date.isNotEmpty) datesByKey['hadir']!.add(date);
      }
      if (hasMasuk && _isLate(masuk)) {
        telat++;
        if (date.isNotEmpty) datesByKey['telat']!.add(date);
      }
      if (_isAlphaStatus(explicit)) {
        alpha++;
        if (date.isNotEmpty) datesByKey['alpha']!.add(date);
      }
    }

    final leaveCount = <String, int>{'izin': 0, 'sakit': 0, 'cuti': 0};
    for (final row in _leaveRows) {
      final type = (row['type'] ?? row['leave_type'] ?? '').toString().toLowerCase();
      if (!leaveCount.containsKey(type)) continue;
      leaveCount[type] = leaveCount[type]! + 1;
      final date = (row['date_start'] ?? row['tanggal_mulai'] ?? row['date'] ?? '').toString();
      if (date.isNotEmpty) datesByKey[type]!.add(date);
    }

    return _MonthSummary(
      hadir: hadir,
      telat: telat,
      izin: leaveCount['izin'] ?? 0,
      sakit: leaveCount['sakit'] ?? 0,
      cuti: leaveCount['cuti'] ?? 0,
      alpha: alpha,
      datesByKey: datesByKey,
    );
  }

  static String _rowStatus(Map<String, dynamic> row) {
    final direct = (row['attendance_status'] ?? row['status'] ?? '').toString().toLowerCase();
    if (direct.isNotEmpty) return direct;
    final masuk = row['masuk'];
    if (masuk is Map) return (masuk['attendance_status'] ?? masuk['status'] ?? '').toString().toLowerCase();
    return '';
  }

  static bool _isLate(Map<dynamic, dynamic> masuk) {
    final status = (masuk['attendance_status'] ?? masuk['status'] ?? '').toString().toLowerCase();
    return status == 'terlambat' || status == 'telat' || status == 'late';
  }

  static bool _isAlphaStatus(String status) => status == 'alpha' || status == 'alpa' || status == 'mangkir';

  void _showCalendarSheet(_MonthSummary summary) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CalendarSheet(
        month: _month,
        rows: _rows,
        leaveRows: _leaveRows,
      ),
    );
  }

  void _showSummaryDetail(String title, List<String> dates, Color color) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DateListSheet(title: title, dates: dates, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StickyCurveHeader(
            title: 'Riwayat Presensi',
            subtitle: 'Rekam jejak kehadiran dan pengajuan',
            icon: Icons.history_rounded,
            height: 108,
          ),
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
              children: [
                _MonthFilter(
                  monthLabel: AppDate.monthLabel(_month),
                  onPrev: () => _changeMonth(-1),
                  onNext: () => _changeMonth(1),
                ),
                const SizedBox(height: 10),
                _CalendarButton(onTap: () => _showCalendarSheet(summary), month: _month),
                const SizedBox(height: 16),
                const _SectionTitle('Ringkasan Bulan Ini'),
                const SizedBox(height: 10),
                _SummaryGrid(
                  summary: summary,
                  onTap: (key, title, color) => _showSummaryDetail(
                    title,
                    summary.datesByKey[key] ?? const [],
                    color,
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionTitle('Daftar Presensi'),
                const SizedBox(height: 10),
                if (_loading)
                  const AppCard(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                  )
                else if (_rows.isEmpty && _leaveRows.isEmpty)
                  const AppCard(
                    child: Padding(
                      padding: EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_rounded, color: AppColors.muted, size: 38),
                          SizedBox(height: 10),
                          Text(
                            'Belum ada riwayat presensi pada bulan ini.',
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
                  ..._rows.map(_HistoryItem.new),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text));
}

class _MonthSummary {
  final int hadir;
  final int telat;
  final int izin;
  final int sakit;
  final int cuti;
  final int alpha;
  final Map<String, List<String>> datesByKey;

  const _MonthSummary({required this.hadir, required this.telat, required this.izin, required this.sakit, required this.cuti, required this.alpha, required this.datesByKey});
}

class _MonthFilter extends StatelessWidget {
  final String monthLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _MonthFilter({required this.monthLabel, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      radius: 22,
      child: Row(
        children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left_rounded, color: AppColors.text)),
          Expanded(child: Text(monthLabel, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.text))),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded, color: AppColors.text)),
        ],
      ),
    );
  }
}

class _CalendarButton extends StatelessWidget {
  final DateTime month;
  final VoidCallback onTap;
  const _CalendarButton({required this.month, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      radius: 22,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
        ),
        title: const Text('Lihat Kehadiran 1 Bulan', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text)),
        subtitle: Text('Ringkasan kehadiran harian ${AppDate.monthLabel(month)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final _MonthSummary summary;
  final void Function(String key, String title, Color color) onTap;
  const _SummaryGrid({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryData('hadir', 'Hadir', summary.hadir, AppColors.green, const Color(0xFFEAFBF2), Icons.check_circle_rounded),
      _SummaryData('telat', 'Telat', summary.telat, AppColors.orange, const Color(0xFFFFF8E8), Icons.schedule_rounded),
      _SummaryData('izin', 'Izin', summary.izin, AppColors.blue, const Color(0xFFEFF6FF), Icons.event_note_rounded),
      _SummaryData('sakit', 'Sakit', summary.sakit, AppColors.red, const Color(0xFFFFF0F3), Icons.medical_services_rounded),
      _SummaryData('cuti', 'Cuti', summary.cuti, const Color(0xFFCE7A00), const Color(0xFFFFF8E8), Icons.work_history_rounded),
      _SummaryData('alpha', 'Alpha', summary.alpha, AppColors.purple, const Color(0xFFF5F0FF), Icons.person_off_rounded),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.14, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemBuilder: (context, index) {
        final item = cards[index];
        return _SummaryCard(data: item, onTap: () => onTap(item.key, item.label, item.color));
      },
    );
  }
}

class _SummaryData {
  final String key;
  final String label;
  final int value;
  final Color color;
  final Color bg;
  final IconData icon;
  const _SummaryData(this.key, this.label, this.value, this.color, this.bg, this.icon);
}

class _SummaryCard extends StatelessWidget {
  final _SummaryData data;
  final VoidCallback onTap;
  const _SummaryCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      color: data.bg,
      radius: 17,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(data.icon, color: data.color, size: 20),
            const SizedBox(height: 5),
            Text('${data.value}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: data.color)),
            const SizedBox(height: 2),
            Text(data.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: data.color.withValues(alpha: .78))),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Map<String, dynamic> row;
  const _HistoryItem(this.row);

  String _timeOf(String key) {
    final value = row[key];
    if (value is Map) return (value['time'] ?? value['waktu'] ?? '--:--').toString();
    return '--:--';
  }

  Map<dynamic, dynamic>? get _masuk => row['masuk'] is Map ? row['masuk'] as Map : null;
  Map<dynamic, dynamic>? get _pulang => row['pulang'] is Map ? row['pulang'] as Map : null;

  bool get _isLate => _masuk != null && _HistoryPageState._isLate(_masuk!);

  int? _lateMinute() {
    final masuk = _masuk;
    if (masuk == null) return null;
    final direct = int.tryParse((masuk['late_minute'] ?? masuk['late_minutes'] ?? masuk['minutes_late'] ?? '').toString());
    if (direct != null && direct > 0) return direct;
    final actual = _minutes(_timeOf('masuk'));
    final workStart = _minutes((masuk['work_start'] ?? row['work_start'] ?? '').toString());
    if (actual == null || workStart == null) return null;
    final diff = actual - workStart;
    return diff > 0 ? diff : null;
  }

  int? _minutes(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  @override
  Widget build(BuildContext context) {
    final date = row['date']?.toString() ?? '-';
    final parsed = DateTime.tryParse(date);
    final complete = _masuk != null && _pulang != null;
    final lateMinute = _lateMinute();
    final statusLabel = _isLate ? 'TERLAMBAT' : complete || _masuk != null || _pulang != null ? 'HADIR' : 'TANPA DATA';
    final statusColor = _isLate ? AppColors.orange : complete || _masuk != null || _pulang != null ? AppColors.green : AppColors.muted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: statusColor.withValues(alpha: .12), borderRadius: BorderRadius.circular(15)),
              child: Icon(_isLate ? Icons.schedule_rounded : Icons.event_available_rounded, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(parsed == null ? date : AppDate.dayDate(parsed), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.text)),
                  const SizedBox(height: 5),
                  Text('Masuk ${_timeOf('masuk')} • Pulang ${_timeOf('pulang')}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.text)),
                  if (_isLate && lateMinute != null) ...[
                    const SizedBox(height: 4),
                    Text('Telat $lateMinute menit', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.orange)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: .12), borderRadius: BorderRadius.circular(999)),
              child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarSheet extends StatelessWidget {
  final DateTime month;
  final List<Map<String, dynamic>> rows;
  final List<Map<String, dynamic>> leaveRows;
  const _CalendarSheet({required this.month, required this.rows, required this.leaveRows});

  Color _colorFor(DateTime date) {
    final key = AppDate.dateKey(date);
    final matching = rows.where((item) => item['date'] == key).toList();
    if (matching.isNotEmpty) {
      final row = matching.first;
      final masuk = row['masuk'];
      final pulang = row['pulang'];
      final hasMasuk = masuk is Map;
      final hasPulang = pulang is Map;
      final explicitStatus = _HistoryPageState._rowStatus(row);
      if (_HistoryPageState._isAlphaStatus(explicitStatus)) return AppColors.red;
      if (hasMasuk && hasPulang) return AppColors.green;
      if (hasMasuk && _HistoryPageState._isLate(masuk)) return AppColors.orange;
      if (hasMasuk || hasPulang) return AppColors.green;
    }
    final leave = leaveRows.where((item) => (item['date_start'] ?? item['tanggal_mulai'] ?? item['date'] ?? '').toString() == key).toList();
    if (leave.isNotEmpty) return AppColors.blue;
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) return const Color(0xFFD9E1EA);
    return const Color(0xFFE9EEF4);
  }

  @override
  Widget build(BuildContext context) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final first = DateTime(month.year, month.month, 1);
    final leading = first.weekday % 7;
    final total = leading + lastDay;
    return DraggableScrollableSheet(
      initialChildSize: .78,
      minChildSize: .48,
      maxChildSize: .94,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text('Kehadiran: ${AppDate.monthLabel(month).toUpperCase()}', style: const TextStyle(fontSize: 15, letterSpacing: 2, fontWeight: FontWeight.w900, color: AppColors.muted)),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: const ['M', 'S', 'S', 'R', 'K', 'J', 'S'].map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900))))).toList()),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: total,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
                    itemBuilder: (context, index) {
                      if (index < leading) return const SizedBox.shrink();
                      final day = index - leading + 1;
                      final date = DateTime(month.year, month.month, day);
                      final color = _colorFor(date);
                      return Container(
                        decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: .45))),
                        alignment: Alignment.center,
                        child: Text('$day', style: TextStyle(fontWeight: FontWeight.w900, color: color)),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  const Wrap(
                    spacing: 14,
                    runSpacing: 10,
                    children: [
                      _Legend(color: AppColors.green, label: 'HADIR'),
                      _Legend(color: AppColors.orange, label: 'TELAT'),
                      _Legend(color: AppColors.blue, label: 'IZIN/SAKIT'),
                      _Legend(color: AppColors.red, label: 'ALPHA'),
                      _Legend(color: Color(0xFFD9E1EA), label: 'LIBUR'),
                      _Legend(color: Color(0xFFE9EEF4), label: 'TANPA DATA'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 13, height: 13, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.muted))]);
}

class _DateListSheet extends StatelessWidget {
  final String title;
  final List<String> dates;
  final Color color;
  const _DateListSheet({required this.title, required this.dates, required this.color});

  @override
  Widget build(BuildContext context) {
    final parsedDates = dates.map(DateTime.tryParse).whereType<DateTime>().toList()..sort();
    return Container(
      decoration: const BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 18),
            Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.event_note_rounded, color: color)), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.text)))]),
            const SizedBox(height: 14),
            if (parsedDates.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Tidak ada tanggal pada kategori ini.', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted)))
            else
              ...parsedDates.map((date) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [Icon(Icons.calendar_today_rounded, color: color, size: 18), const SizedBox(width: 10), Text(AppDate.dayDate(date), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.text))])),
                  )),
          ],
        ),
      ),
    );
  }
}
