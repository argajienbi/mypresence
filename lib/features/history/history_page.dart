import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_session.dart';
import '../../core/utils.dart';
import '../../services/attendance_service.dart';
import '../../services/leave_service.dart';
import '../../services/schedule_service.dart';
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
  final ScheduleService _schedule = ScheduleService();

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;
  List<Map<String, dynamic>> _leaveRows = [];
  List<Map<String, dynamic>> _overtimeRows = [];
  List<DailyHistoryStatus> _dailyStatuses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final firstDay = DateTime(_month.year, _month.month, 1);
      final lastDay = DateTime(_month.year, _month.month + 1, 0);
      final results = await Future.wait([
        _attendance.getMonthlyHistory(session: widget.session, month: _month),
        _leave.getMonthlyRequests(session: widget.session, month: _month),
        _leave.getMonthlyApprovedOvertime(session: widget.session, month: _month),
        _schedule.resolveRange(widget.session, firstDay, lastDay),
      ]);

      final attendanceRows = List<Map<String, dynamic>>.from(results[0] as List);
      final leaveRows = List<Map<String, dynamic>>.from(results[1] as List);
      final overtimeRows = List<Map<String, dynamic>>.from(results[2] as List);
      final schedules = List<DailySchedule>.from(results[3] as List);

      final dailyStatuses = _buildDailyStatuses(
        firstDay: firstDay,
        lastDay: lastDay,
        attendanceRows: attendanceRows,
        leaveRows: leaveRows,
        overtimeRows: overtimeRows,
        schedules: schedules,
      );

      if (!mounted) return;
      setState(() {
        _leaveRows = leaveRows;
        _overtimeRows = overtimeRows;
        _dailyStatuses = dailyStatuses;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _leaveRows = [];
        _overtimeRows = [];
        _dailyStatuses = [];
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
    int alpa = 0;
    int overtimeMinute = 0;

    final datesByKey = <String, Set<String>>{
      'hadir': <String>{},
      'telat': <String>{},
      'izin': <String>{},
      'sakit': <String>{},
      'cuti': <String>{},
      'lembur': <String>{},
      'alpa': <String>{},
    };

    for (final item in _dailyStatuses) {
      switch (item.status) {
        case 'hadir':
          hadir++;
          datesByKey['hadir']!.add(item.dateKey);
          break;
        case 'telat':
          telat++;
          datesByKey['telat']!.add(item.dateKey);
          break;
        case 'izin':
        case 'sakit':
        case 'cuti':
          datesByKey[item.status]!.add(item.dateKey);
          break;
        case 'alpa':
          alpa++;
          datesByKey['alpa']!.add(item.dateKey);
          break;
      }
    }

    final overtimeMap = _expandDateRows(
      _overtimeRows,
      firstDay: DateTime(_month.year, _month.month, 1),
      lastDay: DateTime(_month.year, _month.month + 1, 0),
      startKeys: const ['overtime_date', 'date_start', 'tanggal_mulai', 'date'],
      endKeys: const ['date_end', 'tanggal_selesai', 'overtime_date', 'date_start', 'tanggal_mulai', 'date'],
    );
    for (final date in overtimeMap.keys) {
      datesByKey['lembur']!.add(date);
    }
    for (final row in _overtimeRows) {
      overtimeMinute += int.tryParse((row['overtime_duration_minute'] ?? '0').toString()) ?? 0;
    }

    final resolvedDates = <String, List<String>>{
      for (final entry in datesByKey.entries) entry.key: (entry.value.toList()..sort()),
    };

    return _MonthSummary(
      hadir: hadir,
      telat: telat,
      izin: datesByKey['izin']!.length,
      sakit: datesByKey['sakit']!.length,
      cuti: datesByKey['cuti']!.length,
      lembur: overtimeMap.length,
      lemburMinute: overtimeMinute,
      alpa: alpa,
      datesByKey: resolvedDates,
    );
  }

  void _showCalendarSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CalendarSheet(
        month: _month,
        dailyStatuses: _dailyStatuses,
        overtimeRows: _overtimeRows,
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

  List<DailyHistoryStatus> _buildDailyStatuses({
    required DateTime firstDay,
    required DateTime lastDay,
    required List<Map<String, dynamic>> attendanceRows,
    required List<Map<String, dynamic>> leaveRows,
    required List<Map<String, dynamic>> overtimeRows,
    required List<DailySchedule> schedules,
  }) {
    final attendanceByDate = <String, Map<String, dynamic>>{
      for (final row in attendanceRows)
        if (asString(row['date']).isNotEmpty) asString(row['date']): row,
    };
    final leaveByDate = _expandDateRows(
      leaveRows,
      firstDay: firstDay,
      lastDay: lastDay,
      startKeys: const ['date_start', 'tanggal_mulai', 'date'],
      endKeys: const ['date_end', 'tanggal_selesai', 'date_start', 'tanggal_mulai', 'date'],
    );
    final overtimeByDate = _expandDateRows(
      overtimeRows,
      firstDay: firstDay,
      lastDay: lastDay,
      startKeys: const ['overtime_date', 'date_start', 'tanggal_mulai', 'date'],
      endKeys: const ['date_end', 'tanggal_selesai', 'overtime_date', 'date_start', 'tanggal_mulai', 'date'],
    );
    final today = DateTime.now();
    final todayKey = AppDate.dateKey(today);
    final items = <DailyHistoryStatus>[];

    for (var current = lastDay; !current.isBefore(firstDay); current = current.subtract(const Duration(days: 1))) {
      final index = current.difference(firstDay).inDays;
      final schedule = index >= 0 && index < schedules.length ? schedules[index] : null;
      final dateKey = AppDate.dateKey(current);
      final attendanceRow = attendanceByDate[dateKey];
      final leaveRow = leaveByDate[dateKey];
      final overtimeRow = overtimeByDate[dateKey];
      final status = _resolveDailyStatus(
        date: current,
        dateKey: dateKey,
        schedule: schedule,
        attendanceRow: attendanceRow,
        leaveRow: leaveRow,
        todayKey: todayKey,
      );

      items.add(
        DailyHistoryStatus(
          date: current,
          dateKey: dateKey,
          status: status,
          attendanceRow: attendanceRow,
          leaveRow: leaveRow,
          schedule: schedule,
          overtimeRow: overtimeRow,
        ),
      );
    }

    return items;
  }

  static Map<String, Map<String, dynamic>> _expandDateRows(
    List<Map<String, dynamic>> rows, {
    required DateTime firstDay,
    required DateTime lastDay,
    required List<String> startKeys,
    required List<String> endKeys,
  }) {
    final result = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final start = _parseRowDate(row, startKeys);
      final end = _parseRowDate(row, endKeys) ?? start;
      if (start == null || end == null) continue;
      final normalizedStart = start.isBefore(firstDay) ? firstDay : start;
      final normalizedEnd = end.isAfter(lastDay) ? lastDay : end;
      if (normalizedStart.isAfter(normalizedEnd)) continue;
      for (var current = normalizedStart; !current.isAfter(normalizedEnd); current = current.add(const Duration(days: 1))) {
        result[AppDate.dateKey(current)] = row;
      }
    }
    return result;
  }

  static DateTime? _parseRowDate(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) continue;
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    return null;
  }

  String _resolveDailyStatus({
    required DateTime date,
    required String dateKey,
    required DailySchedule? schedule,
    required Map<String, dynamic>? attendanceRow,
    required Map<String, dynamic>? leaveRow,
    required String todayKey,
  }) {
    if (leaveRow != null) {
      return _leaveStatus(leaveRow);
    }

    if (attendanceRow != null) {
      final status = _attendanceStatus(attendanceRow);
      if (status.isNotEmpty) {
        return status;
      }
    }

    if (schedule == null) return 'tanpa_data';
    if (schedule.isHoliday) return 'libur';
    if (!schedule.isWorkday) {
      return schedule.source == 'none' ? 'tanpa_data' : 'libur';
    }

    final canEvaluateAlpa =
        _checkInStartMinute(schedule) != null && _checkInEndMinute(schedule) != null;
    if (!canEvaluateAlpa) return 'jadwal';

    if (dateKey.compareTo(todayKey) > 0) return 'jadwal';
    if (dateKey == todayKey) {
      return _checkInWindowClosed(schedule, DateTime.now()) ? 'alpa' : 'jadwal';
    }
    return 'alpa';
  }

  String _attendanceStatus(Map<String, dynamic> row) {
    final masuk = row['masuk'];
    final pulang = row['pulang'];
    final hasMasuk = masuk is Map;
    final hasPulang = pulang is Map;
    if (hasMasuk && _isLate(masuk)) return 'telat';
    if (hasMasuk || hasPulang) return 'hadir';
    final direct = (row['attendance_status'] ?? row['status'] ?? '').toString().toLowerCase();
    if (direct == 'terlambat' || direct == 'telat' || direct == 'late') return 'telat';
    if (direct == 'hadir') return 'hadir';
    return '';
  }

  String _leaveStatus(Map<String, dynamic> row) {
    final type = (row['type'] ?? row['leave_type'] ?? 'izin').toString().toLowerCase();
    switch (type) {
      case 'sakit':
        return 'sakit';
      case 'cuti':
        return 'cuti';
      default:
        return 'izin';
    }
  }

  int? _checkInStartMinute(DailySchedule schedule) {
    final checkInStart = _minutesOfDay(schedule.checkInStart);
    if (checkInStart >= 0) return checkInStart;

    final workStart = _minutesOfDay(schedule.workStart);
    if (workStart >= 0) return workStart;

    return null;
  }

  int? _checkInEndMinute(DailySchedule schedule) {
    final checkInEnd = _minutesOfDay(schedule.checkInEnd);
    if (checkInEnd >= 0) return checkInEnd;

    final workStart = _minutesOfDay(schedule.workStart);
    if (workStart >= 0) {
      const minutesPerDay = 24 * 60;
      return (workStart + schedule.lateToleranceMinute) % minutesPerDay;
    }

    final fallback = _minutesOfDay(schedule.checkInStart);
    if (fallback >= 0) return fallback;

    return null;
  }

  bool _checkInWindowClosed(DailySchedule schedule, DateTime now) {
    final startMinute = _checkInStartMinute(schedule);
    final endMinute = _checkInEndMinute(schedule);
    if (startMinute == null || endMinute == null) return false;
    return !_isTimeInWindow(now, startMinute, endMinute);
  }

  static bool _isLate(Map<dynamic, dynamic> masuk) {
    final status = (masuk['attendance_status'] ?? masuk['status'] ?? '').toString().toLowerCase();
    return status == 'terlambat' || status == 'telat' || status == 'late';
  }

  static int _minutesOfDay(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return -1;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return -1;
    return hour * 60 + minute;
  }

  static bool _isTimeInWindow(DateTime dateTime, int startMinute, int endMinute) {
    final current = dateTime.hour * 60 + dateTime.minute;
    if (startMinute <= endMinute) {
      return current >= startMinute && current <= endMinute;
    }
    return current >= startMinute || current <= endMinute;
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'hadir':
        return AppColors.green;
      case 'telat':
        return AppColors.orange;
      case 'izin':
        return AppColors.blue;
      case 'sakit':
        return AppColors.red;
      case 'cuti':
        return const Color(0xFFCE7A00);
      case 'alpa':
        return AppColors.red;
      case 'jadwal':
        return AppColors.muted;
      case 'libur':
        return const Color(0xFFD9E1EA);
      default:
        return const Color(0xFFE9EEF4);
    }
  }

  static IconData _statusIcon(String status) {
    switch (status) {
      case 'hadir':
        return Icons.event_available_rounded;
      case 'telat':
        return Icons.schedule_rounded;
      case 'izin':
        return Icons.event_note_rounded;
      case 'sakit':
        return Icons.medical_services_rounded;
      case 'cuti':
        return Icons.work_history_rounded;
      case 'alpa':
        return Icons.person_off_rounded;
      case 'jadwal':
        return Icons.event_available_rounded;
      case 'libur':
        return Icons.beach_access_rounded;
      default:
        return Icons.inbox_rounded;
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'hadir':
        return 'HADIR';
      case 'telat':
        return 'TELAT';
      case 'izin':
        return 'IZIN';
      case 'sakit':
        return 'SAKIT';
      case 'cuti':
        return 'CUTI';
      case 'alpa':
        return 'ALPA';
      case 'jadwal':
        return 'JADWAL';
      case 'libur':
        return 'LIBUR';
      default:
        return 'TANPA DATA';
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary();
    final visibleDailyStatuses = _dailyStatuses.where((item) => item.status != 'libur' && item.status != 'tanpa_data').toList(growable: false);
    final hasAnyData =
        visibleDailyStatuses.isNotEmpty || _leaveRows.isNotEmpty || _overtimeRows.isNotEmpty;

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
                _CalendarButton(onTap: _showCalendarSheet, month: _month),
                const SizedBox(height: 16),
                const _SectionTitle('Ringkasan Bulan Ini'),
                const SizedBox(height: 10),
                _SummaryHorizontalList(
                  summary: summary,
                  onTap: (key, title, color) => _showSummaryDetail(
                    title,
                    summary.datesByKey[key] ?? const <String>[],
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
                else if (!hasAnyData)
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
                else ...[
                  if (visibleDailyStatuses.isEmpty)
                    const AppCard(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'Belum ada status presensi harian untuk bulan ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  else
                    ...visibleDailyStatuses.map(_DailyHistoryItem.new),
                  if (_leaveRows.isNotEmpty || _overtimeRows.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const _SectionNote(
                      'Detail ini hanya arsip pengajuan, status harian tetap terlihat di Daftar Presensi.',
                    ),
                  ],
                  if (_leaveRows.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const _SectionTitle('Detail Pengajuan Disetujui'),
                    const SizedBox(height: 10),
                    ..._leaveRows.map(_LeaveHistoryItem.new),
                  ],
                  if (_overtimeRows.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const _SectionTitle('Detail Lembur Disetujui'),
                    const SizedBox(height: 10),
                    ..._overtimeRows.map(_OvertimeHistoryItem.new),
                  ],
                ],
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
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppColors.text,
      ),
    );
  }
}

class _SectionNote extends StatelessWidget {
  final String text;

  const _SectionNote(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.muted,
        height: 1.4,
      ),
    );
  }
}

class _MonthSummary {
  final int hadir;
  final int telat;
  final int izin;
  final int sakit;
  final int cuti;
  final int lembur;
  final int lemburMinute;
  final int alpa;
  final Map<String, List<String>> datesByKey;

  const _MonthSummary({
    required this.hadir,
    required this.telat,
    required this.izin,
    required this.sakit,
    required this.cuti,
    required this.lembur,
    required this.lemburMinute,
    required this.alpa,
    required this.datesByKey,
  });
}

class _MonthFilter extends StatelessWidget {
  final String monthLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthFilter({
    required this.monthLabel,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      radius: 22,
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.text),
          ),
          Expanded(
            child: Text(
              monthLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.text),
          ),
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
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
        ),
        title: const Text(
          'Lihat Kehadiran 1 Bulan',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.text),
        ),
        subtitle: Text(
          'Ringkasan kehadiran harian ${AppDate.monthLabel(month)}',
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      ),
    );
  }
}

class _SummaryHorizontalList extends StatelessWidget {
  final _MonthSummary summary;
  final void Function(String key, String title, Color color) onTap;

  const _SummaryHorizontalList({
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryData('hadir', 'Hadir', summary.hadir, AppColors.green, const Color(0xFFEAFBF2), Icons.check_circle_rounded),
      _SummaryData('telat', 'Telat', summary.telat, AppColors.orange, const Color(0xFFFFF8E8), Icons.schedule_rounded),
      _SummaryData('izin', 'Izin', summary.izin, AppColors.blue, const Color(0xFFEFF6FF), Icons.event_note_rounded),
      _SummaryData('sakit', 'Sakit', summary.sakit, AppColors.red, const Color(0xFFFFF0F3), Icons.medical_services_rounded),
      _SummaryData('cuti', 'Cuti', summary.cuti, const Color(0xFFCE7A00), const Color(0xFFFFF8E8), Icons.work_history_rounded),
      _SummaryData('lembur', 'Lembur', summary.lembur, AppColors.primary, const Color(0xFFEAF7FA), Icons.timelapse_rounded),
      _SummaryData('alpa', 'Alpa', summary.alpa, AppColors.red, const Color(0xFFFFEEF1), Icons.person_off_rounded),
    ];

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = cards[index];
          return _SummaryCard(
            data: item,
            onTap: () => onTap(item.key, item.label, item.color),
          );
        },
      ),
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

  const _SummaryData(
    this.key,
    this.label,
    this.value,
    this.color,
    this.bg,
    this.icon,
  );
}

class _SummaryCard extends StatelessWidget {
  final _SummaryData data;
  final VoidCallback onTap;

  const _SummaryCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 98,
      child: AppCard(
        padding: EdgeInsets.zero,
        color: data.bg,
        radius: 17,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(data.icon, color: data.color, size: 19),
                const SizedBox(height: 4),
                Text(
                  '${data.value}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: data.color,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: data.color.withValues(alpha: .78),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyHistoryItem extends StatelessWidget {
  final DailyHistoryStatus item;

  const _DailyHistoryItem(this.item);

  String _timeOf(Map<String, dynamic>? row, String key) {
    if (row == null) return '--:--';
    final value = row[key];
    if (value is Map) return (value['time'] ?? value['waktu'] ?? '--:--').toString();
    return '--:--';
  }

  int? _lateMinute() {
    final attendance = item.attendanceRow;
    if (attendance == null) return null;
    final masuk = attendance['masuk'];
    if (masuk is! Map) return null;
    final direct = int.tryParse((masuk['late_minute'] ?? masuk['late_minutes'] ?? masuk['minutes_late'] ?? '').toString());
    if (direct != null && direct > 0) return direct;
    final actual = _minutes(_timeOf(attendance, 'masuk'));
    final workStart = _minutes((masuk['work_start'] ?? attendance['work_start'] ?? item.schedule?.workStart ?? '').toString());
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

  String _subtitle() {
    switch (item.status) {
      case 'hadir':
      case 'telat':
        final text = 'Masuk ${_timeOf(item.attendanceRow, 'masuk')} - Pulang ${_timeOf(item.attendanceRow, 'pulang')}';
        return text;
      case 'izin':
      case 'sakit':
      case 'cuti':
        final start = (item.leaveRow?['date_start'] ?? item.leaveRow?['tanggal_mulai'] ?? item.dateKey).toString();
        final end = (item.leaveRow?['date_end'] ?? item.leaveRow?['tanggal_selesai'] ?? start).toString();
        final reason = (item.leaveRow?['reason'] ?? item.leaveRow?['alasan'] ?? '').toString().trim();
        final period = end.isEmpty || end == start ? start : '$start - $end';
        if (reason.isEmpty) return period;
        return '$period - $reason';
      case 'alpa':
        return 'Tidak ada presensi dan tidak ada keterangan.';
      case 'jadwal':
        final message = item.schedule?.message.trim() ?? '';
        return message.isEmpty ? 'Jadwal tersedia. Belum waktunya absen.' : message;
      case 'libur':
        final message = item.schedule?.message.trim() ?? '';
        return message.isEmpty ? 'Hari libur.' : message;
      default:
        return 'Tidak ada jadwal maupun presensi.';
    }
  }

  String? _secondaryText() {
    if (item.status != 'telat') return item.overtimeRow != null ? 'Lembur terjadwal.' : null;
    final lateMinute = _lateMinute();
    if (lateMinute == null) return item.overtimeRow != null ? 'Lembur terjadwal.' : null;
    return 'Telat $lateMinute menit';
  }

  @override
  Widget build(BuildContext context) {
    final color = _HistoryPageState._statusColor(item.status);
    final bg = color.withValues(alpha: .12);
    final badge = _HistoryPageState._statusLabel(item.status);
    final icon = _HistoryPageState._statusIcon(item.status);
    final secondary = _secondaryText();

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
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppDate.dayDate(item.date),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _subtitle(),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  if (secondary != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      secondary,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: item.status == 'telat' ? AppColors.orange : AppColors.primary,
                      ),
                    ),
                  ],
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
                badge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveHistoryItem extends StatelessWidget {
  final Map<String, dynamic> row;
  const _LeaveHistoryItem(this.row);

  String get _type => (row['type'] ?? row['leave_type'] ?? 'izin').toString().toLowerCase();

  String get _label {
    switch (_type) {
      case 'sakit':
        return 'Sakit';
      case 'cuti':
        return 'Cuti';
      default:
        return 'Izin';
    }
  }

  Color get _color {
    switch (_type) {
      case 'sakit':
        return AppColors.red;
      case 'cuti':
        return const Color(0xFFCE7A00);
      default:
        return AppColors.blue;
    }
  }

  IconData get _icon {
    switch (_type) {
      case 'sakit':
        return Icons.medical_services_rounded;
      case 'cuti':
        return Icons.work_history_rounded;
      default:
        return Icons.event_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = (row['date_start'] ?? row['tanggal_mulai'] ?? row['date'] ?? '-').toString();
    final end = (row['date_end'] ?? row['tanggal_selesai'] ?? start).toString();
    final reason = (row['reason'] ?? row['alasan'] ?? '').toString().trim();
    final dateText = end.isEmpty || end == start ? start : '$start - $end';

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
              decoration: BoxDecoration(
                color: _color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(_icon, color: _color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_label Disetujui',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    dateText,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: _color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OvertimeHistoryItem extends StatelessWidget {
  final Map<String, dynamic> row;
  const _OvertimeHistoryItem(this.row);

  @override
  Widget build(BuildContext context) {
    final date = (row['overtime_date'] ?? row['date_start'] ?? row['tanggal_mulai'] ?? row['date'] ?? '-').toString();
    final start = (row['overtime_start_time'] ?? '').toString();
    final end = (row['overtime_end_time'] ?? '').toString();
    final reason = (row['reason'] ?? row['alasan'] ?? '').toString().trim();
    final duration = int.tryParse((row['overtime_duration_minute'] ?? '0').toString()) ?? 0;
    final durationText = _formatDuration(duration);

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
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.timelapse_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lembur Disetujui',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$date - $start - $end',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Durasi $durationText',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'LEMBUR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(int minutes) {
    if (minutes <= 0) return '-';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    if (hours <= 0) return '$minutes menit';
    if (remain == 0) return '$hours jam';
    return '$hours jam $remain menit';
  }
}

class _CalendarSheet extends StatelessWidget {
  final DateTime month;
  final List<DailyHistoryStatus> dailyStatuses;
  final List<Map<String, dynamic>> overtimeRows;

  const _CalendarSheet({
    required this.month,
    required this.dailyStatuses,
    required this.overtimeRows,
  });

  @override
  Widget build(BuildContext context) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final first = DateTime(month.year, month.month, 1);
    final leading = first.weekday % 7;
    final total = leading + lastDay;
    final dailyByDate = {
      for (final item in dailyStatuses) item.dateKey: item,
    };
    final overtimeByDate = <String, Map<String, dynamic>>{
      for (final entry in _HistoryPageState._expandDateRows(
        overtimeRows,
        firstDay: DateTime(month.year, month.month, 1),
        lastDay: DateTime(month.year, month.month + 1, 0),
        startKeys: const ['overtime_date', 'date_start', 'tanggal_mulai', 'date'],
        endKeys: const ['date_end', 'tanggal_selesai', 'overtime_date', 'date_start', 'tanggal_mulai', 'date'],
      ).entries)
        entry.key: entry.value,
    };

    Color colorFor(DateTime date) {
      final key = AppDate.dateKey(date);
      final item = dailyByDate[key];
      final overtime = overtimeByDate[key];
      if (item != null) {
        switch (item.status) {
          case 'hadir':
            return AppColors.green;
          case 'telat':
            return AppColors.orange;
          case 'izin':
            return AppColors.blue;
          case 'sakit':
            return AppColors.red;
          case 'cuti':
            return const Color(0xFFCE7A00);
          case 'alpa':
            return AppColors.red;
          case 'jadwal':
            return overtime != null ? AppColors.primary : AppColors.muted;
          case 'libur':
            return const Color(0xFFD9E1EA);
          case 'tanpa_data':
            return overtime != null ? AppColors.primary : const Color(0xFFE9EEF4);
        }
      }
      if (overtime != null) return AppColors.primary;
      return const Color(0xFFE9EEF4);
    }

    return DraggableScrollableSheet(
      initialChildSize: .78,
      minChildSize: .48,
      maxChildSize: .94,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Kehadiran: ${AppDate.monthLabel(month).toUpperCase()}',
              style: const TextStyle(
                fontSize: 15,
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const ['M', 'S', 'S', 'R', 'K', 'J', 'S']
                        .map(
                          (day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: total,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemBuilder: (context, index) {
                      if (index < leading) return const SizedBox.shrink();
                      final day = index - leading + 1;
                      final date = DateTime(month.year, month.month, day);
                      final color = colorFor(date);
                      return Container(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: color.withValues(alpha: .45)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
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
                      _Legend(color: AppColors.blue, label: 'IZIN'),
                      _Legend(color: AppColors.red, label: 'SAKIT'),
                      _Legend(color: Color(0xFFCE7A00), label: 'CUTI'),
                      _Legend(color: AppColors.primary, label: 'LEMBUR'),
                      _Legend(color: AppColors.muted, label: 'JADWAL'),
                      _Legend(color: AppColors.red, label: 'ALPA'),
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
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _DateListSheet extends StatelessWidget {
  final String title;
  final List<String> dates;
  final Color color;

  const _DateListSheet({
    required this.title,
    required this.dates,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final parsedDates = dates.map(DateTime.tryParse).whereType<DateTime>().toList()..sort();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.event_note_rounded, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (parsedDates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Tidak ada tanggal pada kategori ini.',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted),
                ),
              )
            else
              ...parsedDates.map(
                (date) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, color: color, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          AppDate.dayDate(date),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DailyHistoryStatus {
  final DateTime date;
  final String dateKey;
  final String status;
  final Map<String, dynamic>? attendanceRow;
  final Map<String, dynamic>? leaveRow;
  final DailySchedule? schedule;
  final Map<String, dynamic>? overtimeRow;

  const DailyHistoryStatus({
    required this.date,
    required this.dateKey,
    required this.status,
    required this.attendanceRow,
    required this.leaveRow,
    required this.schedule,
    required this.overtimeRow,
  });
}
