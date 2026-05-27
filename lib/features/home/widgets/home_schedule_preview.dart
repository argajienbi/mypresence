import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/models/app_session.dart';
import '../../../core/utils.dart';
import '../../../services/schedule_service.dart';

enum HomeScheduleMode { day, week, month }

class HomeSchedulePreview extends StatefulWidget {
  final AppSession session;
  final ScheduleService scheduleService;
  final DailySchedule? todaySchedule;
  final bool loadingToday;
  final VoidCallback onOpenTodayDetail;

  const HomeSchedulePreview({
    super.key,
    required this.session,
    required this.scheduleService,
    required this.todaySchedule,
    required this.loadingToday,
    required this.onOpenTodayDetail,
  });

  @override
  State<HomeSchedulePreview> createState() => _HomeSchedulePreviewState();
}

class _HomeSchedulePreviewState extends State<HomeSchedulePreview> {
  HomeScheduleMode _mode = HomeScheduleMode.day;
  DateTime _anchorDate = DateTime.now();
  bool _loading = false;
  List<DailySchedule> _range = const [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadRange();
  }

  @override
  void didUpdateWidget(covariant HomeSchedulePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.uid != widget.session.uid || oldWidget.session.companyId != widget.session.companyId) {
      _loadRange();
    }
  }

  DateTime get _normalizedAnchor => DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day);

  Future<void> _loadRange() async {
    final bounds = _rangeBounds(_mode, _normalizedAnchor);
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final rows = await widget.scheduleService.resolveRange(widget.session, bounds.start, bounds.end);
      if (!mounted) return;
      setState(() => _range = rows);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _range = const [];
        _error = 'Jadwal belum bisa dimuat.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMode(HomeScheduleMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _anchorDate = DateTime.now();
    });
    _loadRange();
  }

  void _shift(int direction) {
    setState(() {
      switch (_mode) {
        case HomeScheduleMode.day:
          _anchorDate = _normalizedAnchor.add(Duration(days: direction));
          break;
        case HomeScheduleMode.week:
          _anchorDate = _normalizedAnchor.add(Duration(days: direction * 7));
          break;
        case HomeScheduleMode.month:
          _anchorDate = DateTime(_anchorDate.year, _anchorDate.month + direction, 1);
          break;
      }
    });
    _loadRange();
  }

  @override
  Widget build(BuildContext context) {
    final selectedSchedule = _scheduleForDate(_normalizedAnchor) ?? (_isToday(_normalizedAnchor) ? widget.todaySchedule : null);
    final status = _scheduleStatus(selectedSchedule, widget.loadingToday && _isToday(_normalizedAnchor));
    final bounds = _rangeBounds(_mode, _normalizedAnchor);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Jadwal',
                  style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
              _NavButton(icon: Icons.chevron_left_rounded, onTap: () => _shift(-1)),
              const SizedBox(width: 6),
              _NavButton(icon: Icons.chevron_right_rounded, onTap: () => _shift(1)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ModeChip(label: 'Harian', selected: _mode == HomeScheduleMode.day, onTap: () => _changeMode(HomeScheduleMode.day)),
              const SizedBox(width: 8),
              _ModeChip(label: 'Mingguan', selected: _mode == HomeScheduleMode.week, onTap: () => _changeMode(HomeScheduleMode.week)),
              const SizedBox(width: 8),
              _ModeChip(label: 'Bulanan', selected: _mode == HomeScheduleMode.month, onTap: () => _changeMode(HomeScheduleMode.month)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _periodLabel(bounds.start, bounds.end),
            style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (_error.isNotEmpty)
            _ErrorBox(message: _error)
          else ...[
            _SelectedScheduleCard(
              date: _normalizedAnchor,
              schedule: selectedSchedule,
              status: status,
              onTap: _isToday(_normalizedAnchor) ? widget.onOpenTodayDetail : null,
            ),
            if (_mode != HomeScheduleMode.day) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: _mode == HomeScheduleMode.week ? 92 : 76,
                child: _loading
                    ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _range.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final date = bounds.start.add(Duration(days: index));
                          final schedule = index < _range.length ? _range[index] : null;
                          final itemStatus = _scheduleStatus(schedule, false);
                          return _ScheduleDateChip(
                            date: date,
                            status: itemStatus,
                            selected: AppDate.dateKey(date) == AppDate.dateKey(_normalizedAnchor),
                            compact: _mode == HomeScheduleMode.month,
                            onTap: () => setState(() => _anchorDate = date),
                          );
                        },
                      ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  DailySchedule? _scheduleForDate(DateTime date) {
    final target = AppDate.dateKey(date);
    final bounds = _rangeBounds(_mode, _normalizedAnchor);
    final index = date.difference(bounds.start).inDays;
    if (index >= 0 && index < _range.length) return _range[index];
    for (var i = 0; i < _range.length; i++) {
      final rowDate = bounds.start.add(Duration(days: i));
      if (AppDate.dateKey(rowDate) == target) return _range[i];
    }
    return null;
  }

  _ScheduleStatus _scheduleStatus(DailySchedule? schedule, bool loading) {
    if (loading) return _ScheduleStatus('Memuat', AppColors.muted, Icons.hourglass_empty_rounded);
    if (schedule == null) return _ScheduleStatus('Belum tersedia', AppColors.muted, Icons.help_outline_rounded);
    if (schedule.overtimeFlag || schedule.source == 'overtime_schedule') return _ScheduleStatus('Lembur', AppColors.purple, Icons.timelapse_rounded);
    if (schedule.isHoliday) return _ScheduleStatus('Libur', AppColors.orange, Icons.beach_access_rounded);
    if (schedule.source == 'special_schedule') return _ScheduleStatus('Khusus', AppColors.blue, Icons.event_available_rounded);
    if (schedule.isWorkday) return _ScheduleStatus('Reguler', AppColors.green, Icons.work_rounded);
    return _ScheduleStatus('Tidak ada', AppColors.muted, Icons.event_busy_rounded);
  }

  _DateRange _rangeBounds(HomeScheduleMode mode, DateTime anchor) {
    switch (mode) {
      case HomeScheduleMode.day:
        return _DateRange(anchor, anchor);
      case HomeScheduleMode.week:
        final start = anchor.subtract(Duration(days: anchor.weekday - 1));
        return _DateRange(start, start.add(const Duration(days: 6)));
      case HomeScheduleMode.month:
        final start = DateTime(anchor.year, anchor.month);
        final end = DateTime(anchor.year, anchor.month + 1, 0);
        return _DateRange(start, end);
    }
  }

  String _periodLabel(DateTime start, DateTime end) {
    if (AppDate.dateKey(start) == AppDate.dateKey(end)) return AppDate.dayDate(start);
    if (_mode == HomeScheduleMode.month) return AppDate.monthLabel(start);
    return '${AppDate.shortDate(start)} - ${AppDate.shortDate(end)}';
  }

  bool _isToday(DateTime date) => AppDate.dateKey(date) == AppDate.dateKey(DateTime.now());
}

class _DateRange {
  final DateTime start;
  final DateTime end;

  const _DateRange(this.start, this.end);
}

class _ScheduleStatus {
  final String label;
  final Color color;
  final IconData icon;

  const _ScheduleStatus(this.label, this.color, this.icon);
}

class _SelectedScheduleCard extends StatelessWidget {
  final DateTime date;
  final DailySchedule? schedule;
  final _ScheduleStatus status;
  final VoidCallback? onTap;

  const _SelectedScheduleCard({
    required this.date,
    required this.schedule,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final workTime = _workTime(schedule);
    final checkIn = _timeRange(schedule?.checkInStart, schedule?.checkInEnd);
    final checkOut = _timeRange(schedule?.checkOutStart, schedule?.checkOutEnd);
    final source = _sourceLabel(schedule);

    return Material(
      color: status.color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: status.color.withValues(alpha: .18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(status.icon, color: status.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppDate.dayDate(date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w900),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: status.color.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(status.label, style: TextStyle(color: status.color, fontSize: 10.5, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      schedule?.timetableName.isNotEmpty == true ? schedule!.timetableName : source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.text, fontSize: 14.5, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      workTime,
                      style: TextStyle(color: status.color, fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _MiniScheduleInfo(label: 'Check-in', value: checkIn),
                        _MiniScheduleInfo(label: 'Check-out', value: checkOut),
                        _MiniScheduleInfo(label: 'Sumber', value: source),
                      ],
                    ),
                    if (schedule?.isHolidayWork == true) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Libur nasional tidak memblokir presensi karena ada jadwal lembur.',
                        style: TextStyle(color: AppColors.muted, fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _workTime(DailySchedule? schedule) {
    if (schedule == null) return 'Jadwal belum tersedia';
    if (!schedule.isWorkday) return schedule.message.isEmpty ? 'Tidak ada jam kerja' : schedule.message;
    final start = schedule.workStart.isNotEmpty ? schedule.workStart : '-';
    final end = schedule.workEnd.isNotEmpty ? schedule.workEnd : '-';
    return '$start - $end';
  }

  String _timeRange(String? start, String? end) {
    final a = (start ?? '').trim();
    final b = (end ?? '').trim();
    if (a.isEmpty && b.isEmpty) return '-';
    return '${a.isEmpty ? '-' : a} - ${b.isEmpty ? '-' : b}';
  }

  String _sourceLabel(DailySchedule? schedule) {
    switch (schedule?.source ?? '') {
      case 'overtime_schedule':
        return 'Jadwal Lembur';
      case 'special_schedule':
        return 'Jadwal Khusus';
      case 'holiday':
        return 'Hari Libur';
      case 'user_assignment':
        return 'Jadwal User';
      case 'group_assignment':
        return 'Jadwal Rutin';
      default:
        return 'Jadwal';
    }
  }
}

class _MiniScheduleInfo extends StatelessWidget {
  final String label;
  final String value;

  const _MiniScheduleInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11.5, height: 1.3),
        children: [
          TextSpan(text: '$label ', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
          TextSpan(text: value, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ScheduleDateChip extends StatelessWidget {
  final DateTime date;
  final _ScheduleStatus status;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _ScheduleDateChip({
    required this.date,
    required this.status,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? status.color.withValues(alpha: .16) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: compact ? 68 : 82,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? status.color.withValues(alpha: .42) : AppColors.line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                compact ? '${date.day}' : AppDate.weekday(date).substring(0, 3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: selected ? status.color : AppColors.text, fontWeight: FontWeight.w900, fontSize: compact ? 18 : 12),
              ),
              if (!compact) ...[
                const SizedBox(height: 2),
                Text('${date.day}', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w900, fontSize: 18)),
              ],
              const SizedBox(height: 5),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: status.color, shape: BoxShape.circle)),
              const SizedBox(height: 3),
              Text(
                status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.primary.withValues(alpha: .13) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: selected ? AppColors.primary.withValues(alpha: .32) : AppColors.line),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.text,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(width: 36, height: 36, child: Icon(icon, color: AppColors.primary)),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.red.withValues(alpha: .18)),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w800)),
    );
  }
}
