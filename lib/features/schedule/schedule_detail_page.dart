import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_session.dart';
import '../../core/utils.dart';
import '../../services/schedule_service.dart';

class ScheduleDetailPage extends StatefulWidget {
  final AppSession session;
  final ScheduleService scheduleService;
  final DailySchedule? initialSchedule;
  final DateTime initialDate;

  const ScheduleDetailPage({
    super.key,
    required this.session,
    required this.scheduleService,
    required this.initialDate,
    this.initialSchedule,
  });

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  ScheduleViewMode _mode = ScheduleViewMode.day;
  late DateTime _selectedDate;
  bool _loading = true;
  DailySchedule? _selectedSchedule;
  List<DailySchedule> _range = const [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _selectedDate = _normalize(widget.initialDate);
    _selectedSchedule = widget.initialSchedule;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final bounds = _rangeBounds(_mode, _selectedDate);
      final range = await widget.scheduleService.resolveRange(widget.session, bounds.start, bounds.end);
      final selected = _scheduleForDate(range, bounds.start, _selectedDate) ??
          await widget.scheduleService.resolveForDate(widget.session, _selectedDate);
      if (!mounted) return;
      setState(() {
        _range = range;
        _selectedSchedule = selected;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _range = const [];
        _selectedSchedule = null;
        _error = 'Jadwal belum bisa dimuat. ${error.toString()}';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMode(ScheduleViewMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _selectedDate = _normalize(DateTime.now());
    });
    _load();
  }

  void _shift(int direction) {
    setState(() {
      switch (_mode) {
        case ScheduleViewMode.day:
          _selectedDate = _selectedDate.add(Duration(days: direction));
          break;
        case ScheduleViewMode.week:
          _selectedDate = _selectedDate.add(Duration(days: direction * 7));
          break;
        case ScheduleViewMode.month:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + direction, 1);
          break;
      }
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final schedule = _selectedSchedule;
    final status = _statusOf(schedule);
    final workTime = _workTime(schedule);
    final checkIn = _rangeText(schedule?.checkInStart, schedule?.checkInEnd);
    final checkOut = _rangeText(schedule?.checkOutStart, schedule?.checkOutEnd);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Detail Jadwal'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            _HeroScheduleCard(
              date: _selectedDate,
              schedule: schedule,
              status: status,
              loading: _loading,
              error: _error,
            ),
            const SizedBox(height: 14),
            _ModeSelector(
              mode: _mode,
              onChanged: _changeMode,
            ),
            const SizedBox(height: 14),
            _DateNavigator(
              label: _periodLabel(),
              onPrev: () => _shift(-1),
              onNext: () => _shift(1),
            ),
            if (_mode != ScheduleViewMode.day) ...[
              const SizedBox(height: 12),
              _DateStrip(
                mode: _mode,
                selectedDate: _selectedDate,
                range: _range,
                rangeStart: _rangeBounds(_mode, _selectedDate).start,
                onPick: (date) {
                  setState(() => _selectedDate = _normalize(date));
                  _load();
                },
              ),
            ],
            const SizedBox(height: 16),
            _TimeLineCard(
              checkIn: checkIn,
              workTime: workTime,
              checkOut: checkOut,
              status: status,
            ),
            const SizedBox(height: 16),
            _InfoSection(
              children: [
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  color: AppColors.blue,
                  label: 'Shift Hari Ini',
                  value: _text(schedule?.shiftName, fallback: schedule?.timetableName ?? '-'),
                ),
                _InfoRow(
                  icon: Icons.groups_rounded,
                  color: AppColors.primary,
                  label: 'Grup / Struktur',
                  value: _groupLabel(),
                ),
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  color: AppColors.green,
                  label: 'Berlaku',
                  value: schedule?.periodLabel ?? 'Belum tersedia',
                ),
                _InfoRow(
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.purple,
                  label: 'Sumber Jadwal',
                  value: _sourceLabel(schedule?.source ?? '-'),
                ),
                _InfoRow(
                  icon: Icons.verified_user_rounded,
                  color: status.color,
                  label: 'Status',
                  value: status.label,
                  valueColor: status.color,
                ),
                _InfoRow(
                  icon: Icons.info_rounded,
                  color: AppColors.orange,
                  label: 'Keterangan',
                  value: schedule?.message ?? 'Jadwal belum tersedia.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

  DailySchedule? _scheduleForDate(List<DailySchedule> range, DateTime start, DateTime target) {
    final index = _normalize(target).difference(_normalize(start)).inDays;
    if (index < 0 || index >= range.length) return null;
    return range[index];
  }

  _DateBounds _rangeBounds(ScheduleViewMode mode, DateTime anchor) {
    final date = _normalize(anchor);
    switch (mode) {
      case ScheduleViewMode.day:
        return _DateBounds(date, date);
      case ScheduleViewMode.week:
        final start = date.subtract(Duration(days: date.weekday - 1));
        return _DateBounds(start, start.add(const Duration(days: 6)));
      case ScheduleViewMode.month:
        final start = DateTime(date.year, date.month);
        final end = DateTime(date.year, date.month + 1, 0);
        return _DateBounds(start, end);
    }
  }

  String _periodLabel() {
    final bounds = _rangeBounds(_mode, _selectedDate);
    if (AppDate.dateKey(bounds.start) == AppDate.dateKey(bounds.end)) return AppDate.dayDate(bounds.start);
    if (_mode == ScheduleViewMode.month) return AppDate.monthLabel(bounds.start);
    return '${AppDate.shortDate(bounds.start)} - ${AppDate.shortDate(bounds.end)}';
  }

  _ScheduleVisualStatus _statusOf(DailySchedule? schedule) {
    if (_loading) return const _ScheduleVisualStatus('Memuat', AppColors.muted, Icons.hourglass_empty_rounded);
    if (_error.isNotEmpty) return const _ScheduleVisualStatus('Error', AppColors.red, Icons.error_rounded);
    if (schedule == null) return const _ScheduleVisualStatus('Belum tersedia', AppColors.orange, Icons.help_rounded);
    if (schedule.overtimeFlag || schedule.source == 'overtime_schedule') return const _ScheduleVisualStatus('Lembur', AppColors.purple, Icons.more_time_rounded);
    if (schedule.isHoliday) return const _ScheduleVisualStatus('Libur', AppColors.orange, Icons.beach_access_rounded);
    if (schedule.source == 'special_schedule') return const _ScheduleVisualStatus('Khusus', AppColors.blue, Icons.event_available_rounded);
    if (schedule.isWorkday) return const _ScheduleVisualStatus('Aktif', AppColors.green, Icons.check_circle_rounded);
    if (schedule.scheduleReady) return const _ScheduleVisualStatus('Tidak Aktif', AppColors.muted, Icons.event_busy_rounded);
    return const _ScheduleVisualStatus('Belum tersedia', AppColors.orange, Icons.help_rounded);
  }

  String _workTime(DailySchedule? schedule) {
    if (schedule == null || !schedule.isWorkday) return '-';
    final start = schedule.workStart.isNotEmpty ? schedule.workStart : schedule.checkInStart;
    final end = schedule.workEnd.isNotEmpty ? schedule.workEnd : schedule.checkOutEnd;
    if (start.isEmpty && end.isEmpty) return '-';
    return '$start - $end';
  }

  String _rangeText(String? start, String? end) {
    final s = (start ?? '').trim();
    final e = (end ?? '').trim();
    if (s.isEmpty && e.isEmpty) return '-';
    return '$s - $e';
  }

  String _text(String? value, {String fallback = '-'}) {
    final text = (value ?? '').trim();
    return text.isEmpty ? fallback : text;
  }

  String _groupLabel() {
    final parts = <String>[
      if (widget.session.groupName.trim().isNotEmpty) widget.session.groupName.trim(),
      if (widget.session.departmentName.trim().isNotEmpty) widget.session.departmentName.trim(),
      if (widget.session.subDepartmentName.trim().isNotEmpty) widget.session.subDepartmentName.trim(),
    ];
    if (parts.isEmpty) return widget.session.officeName.trim().isEmpty ? '-' : widget.session.officeName.trim();
    return parts.join(' — ');
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'overtime_schedule':
        return 'Jadwal Lembur';
      case 'user_assignment':
        return 'Penerapan Jadwal User';
      case 'group_assignment':
        return 'Penerapan Jadwal Rutin';
      case 'special_schedule':
        return 'Jadwal Khusus';
      case 'holiday':
        return 'Hari Libur';
      case 'none':
        return 'Belum ada penerapan jadwal';
      default:
        return source.isEmpty ? '-' : source;
    }
  }
}

enum ScheduleViewMode { day, week, month }

class _DateBounds {
  final DateTime start;
  final DateTime end;
  const _DateBounds(this.start, this.end);
}

class _ScheduleVisualStatus {
  final String label;
  final Color color;
  final IconData icon;
  const _ScheduleVisualStatus(this.label, this.color, this.icon);
}

class _HeroScheduleCard extends StatelessWidget {
  final DateTime date;
  final DailySchedule? schedule;
  final _ScheduleVisualStatus status;
  final bool loading;
  final String error;

  const _HeroScheduleCard({
    required this.date,
    required this.schedule,
    required this.status,
    required this.loading,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final title = schedule?.isWorkday == true
        ? (schedule!.timetableName.isNotEmpty ? schedule!.timetableName : 'Jadwal Hari Ini')
        : 'Jadwal Hari Ini';
    final message = error.isNotEmpty
        ? error
        : loading
            ? 'Memuat data jadwal...'
            : schedule?.message ?? 'Jadwal belum tersedia.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: status.color.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          _IconBox(icon: status.icon, color: status.color, size: 62),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppDate.dayDate(date), style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(color: status.color.withValues(alpha: .12), borderRadius: BorderRadius.circular(999)),
            child: Text(status.label, style: TextStyle(color: status.color, fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final ScheduleViewMode mode;
  final ValueChanged<ScheduleViewMode> onChanged;

  const _ModeSelector({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)),
      child: Row(
        children: [
          _ModeButton(label: 'Harian', selected: mode == ScheduleViewMode.day, onTap: () => onChanged(ScheduleViewMode.day)),
          _ModeButton(label: 'Mingguan', selected: mode == ScheduleViewMode.week, onTap: () => onChanged(ScheduleViewMode.week)),
          _ModeButton(label: 'Bulanan', selected: mode == ScheduleViewMode.month, onTap: () => onChanged(ScheduleViewMode.month)),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: selected ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.muted, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _DateNavigator({required this.label, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _NavButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
        Expanded(
          child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w900)),
        ),
        _NavButton(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class _DateStrip extends StatelessWidget {
  final ScheduleViewMode mode;
  final DateTime selectedDate;
  final List<DailySchedule> range;
  final DateTime rangeStart;
  final ValueChanged<DateTime> onPick;

  const _DateStrip({required this.mode, required this.selectedDate, required this.range, required this.rangeStart, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final count = mode == ScheduleViewMode.week ? 7 : range.length;
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = rangeStart.add(Duration(days: index));
          final schedule = index < range.length ? range[index] : null;
          final selected = AppDate.dateKey(date) == AppDate.dateKey(selectedDate);
          final color = schedule?.isWorkday == true ? AppColors.green : AppColors.muted;
          return InkWell(
            onTap: () => onPick(date),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 62,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: selected ? AppColors.primary : AppColors.line),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${date.day}', style: TextStyle(color: selected ? Colors.white : AppColors.text, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: selected ? Colors.white : color, shape: BoxShape.circle)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimeLineCard extends StatelessWidget {
  final String checkIn;
  final String workTime;
  final String checkOut;
  final _ScheduleVisualStatus status;

  const _TimeLineCard({required this.checkIn, required this.workTime, required this.checkOut, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.line)),
      child: Row(
        children: [
          Expanded(child: _TimeBox(icon: Icons.login_rounded, color: AppColors.green, label: 'Clock In', value: checkIn, status: status.label)),
          _Connector(),
          Expanded(child: _TimeBox(icon: Icons.access_time_rounded, color: AppColors.blue, label: 'Jam Kerja', value: workTime, status: status.label)),
          _Connector(),
          Expanded(child: _TimeBox(icon: Icons.logout_rounded, color: AppColors.purple, label: 'Clock Out', value: checkOut, status: status.label)),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String status;

  const _TimeBox({required this.icon, required this.color, required this.label, required this.value, required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _IconBox(icon: icon, color: color, size: 44),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(value, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppColors.line.withValues(alpha: .65), borderRadius: BorderRadius.circular(999)),
          child: Text(status, style: const TextStyle(color: AppColors.muted, fontSize: 9.5, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 22, height: 2, margin: const EdgeInsets.only(bottom: 20), color: AppColors.line);
  }
}

class _InfoSection extends StatelessWidget {
  final List<Widget> children;

  const _InfoSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.line)),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.icon, required this.color, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          _IconBox(icon: icon, color: color, size: 40),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.text, fontSize: 13.5, fontWeight: FontWeight.w900))),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: valueColor ?? AppColors.text, fontSize: 13, fontWeight: FontWeight.w900))),
        ],
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(width: 48, height: 48, child: Icon(icon, color: AppColors.primary, size: 30)),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _IconBox({required this.icon, required this.color, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: .11), borderRadius: BorderRadius.circular(size * .32)),
      child: Icon(icon, color: color, size: size * .48),
    );
  }
}
