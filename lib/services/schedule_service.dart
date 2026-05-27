import '../core/firebase_paths.dart';
import '../core/models/app_session.dart';
import '../core/utils.dart';
import 'rtdb_service.dart';

class DailySchedule {
  final bool scheduleReady;
  final bool isWorkday;
  final bool isHoliday;
  final String message;
  final String source;
  final String assignmentId;
  final String assignmentStartDate;
  final String assignmentEndDate;
  final String shiftId;
  final String shiftName;
  final String timetableId;
  final String timetableName;
  final String workStart;
  final String workEnd;
  final String checkInStart;
  final String checkInEnd;
  final String checkOutStart;
  final String checkOutEnd;
  final int lateToleranceMinute;
  final int earlyOutToleranceMinute;
  final bool crossesMidnight;
  final bool overtimeFlag;
  final String overtimeScheduleId;
  final bool isHolidayWork;

  const DailySchedule({
    required this.scheduleReady,
    required this.isWorkday,
    required this.isHoliday,
    required this.message,
    required this.source,
    required this.assignmentId,
    this.assignmentStartDate = '',
    this.assignmentEndDate = '',
    required this.shiftId,
    required this.shiftName,
    required this.timetableId,
    required this.timetableName,
    required this.workStart,
    required this.workEnd,
    required this.checkInStart,
    required this.checkInEnd,
    required this.checkOutStart,
    required this.checkOutEnd,
    required this.lateToleranceMinute,
    required this.earlyOutToleranceMinute,
    required this.crossesMidnight,
    this.overtimeFlag = false,
    this.overtimeScheduleId = '',
    this.isHolidayWork = false,
  });

  String get periodLabel {
    if (assignmentStartDate.isEmpty && assignmentEndDate.isEmpty) return 'Belum tersedia';
    final start = assignmentStartDate.isEmpty ? 'Mulai belum diatur' : _formatDateLabel(assignmentStartDate);
    final end = assignmentEndDate.isEmpty ? 'Seterusnya' : _formatDateLabel(assignmentEndDate);
    return '$start - $end';
  }

  static String _formatDateLabel(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  static DailySchedule holiday(String message) {
    return DailySchedule(
      scheduleReady: true,
      isWorkday: false,
      isHoliday: true,
      message: message,
      source: 'holiday',
      assignmentId: '',
      shiftId: '',
      shiftName: '',
      timetableId: '',
      timetableName: '',
      workStart: '',
      workEnd: '',
      checkInStart: '',
      checkInEnd: '',
      checkOutStart: '',
      checkOutEnd: '',
      lateToleranceMinute: 0,
      earlyOutToleranceMinute: 0,
      crossesMidnight: false,
    );
  }

  static DailySchedule off(String message, {String source = 'none', String assignmentId = '', String assignmentStartDate = '', String assignmentEndDate = '', String shiftId = '', String shiftName = '', bool scheduleReady = false}) {
    return DailySchedule(
      scheduleReady: scheduleReady,
      isWorkday: false,
      isHoliday: false,
      message: message,
      source: source,
      assignmentId: assignmentId,
      assignmentStartDate: assignmentStartDate,
      assignmentEndDate: assignmentEndDate,
      shiftId: shiftId,
      shiftName: shiftName,
      timetableId: '',
      timetableName: '',
      workStart: '',
      workEnd: '',
      checkInStart: '',
      checkInEnd: '',
      checkOutStart: '',
      checkOutEnd: '',
      lateToleranceMinute: 0,
      earlyOutToleranceMinute: 0,
      crossesMidnight: false,
    );
  }

  static DailySchedule overtime({
    required Map<String, dynamic> item,
    required String scheduleId,
    required String date,
    required bool holidayWork,
  }) {
    return DailySchedule(
      scheduleReady: true,
      isWorkday: true,
      isHoliday: false,
      message: holidayWork ? 'Jadwal lembur aktif pada hari libur.' : 'Jadwal lembur aktif.',
      source: 'overtime_schedule',
      assignmentId: scheduleId,
      assignmentStartDate: date,
      assignmentEndDate: date,
      shiftId: '',
      shiftName: 'Jadwal Lembur',
      timetableId: scheduleId,
      timetableName: asString(item['name'], 'Jadwal Lembur'),
      workStart: asString(item['work_start']),
      workEnd: asString(item['work_end']),
      checkInStart: asString(item['check_in_start']),
      checkInEnd: asString(item['check_in_end']),
      checkOutStart: asString(item['check_out_start']),
      checkOutEnd: asString(item['check_out_end']),
      lateToleranceMinute: asInt(item['late_tolerance_minute']),
      earlyOutToleranceMinute: asInt(item['early_out_tolerance_minute']),
      crossesMidnight: _timeCrossesMidnight(asString(item['work_start']), asString(item['work_end'])),
      overtimeFlag: true,
      overtimeScheduleId: scheduleId,
      isHolidayWork: holidayWork,
    );
  }

  Map<String, dynamic> toAttendancePayload() {
    return <String, dynamic>{
      'schedule_ready': scheduleReady,
      'today_active': isWorkday,
      'assignment_id': assignmentId,
      'assignment_start_date': assignmentStartDate,
      'assignment_end_date': assignmentEndDate,
      'shift_id': shiftId,
      'shift_name': shiftName,
      'timetable_id': timetableId,
      'timetable_name': timetableName,
      'schedule_source': source,
      'work_start': workStart,
      'work_end': workEnd,
      'check_in_start': checkInStart,
      'check_in_end': checkInEnd,
      'check_out_start': checkOutStart,
      'check_out_end': checkOutEnd,
      'late_tolerance_minute': lateToleranceMinute,
      'early_out_tolerance_minute': earlyOutToleranceMinute,
      'crosses_midnight': crossesMidnight,
      'overtime_flag': overtimeFlag,
      'overtime_schedule_id': overtimeScheduleId,
      'is_holiday_work': isHolidayWork,
    };
  }

  static bool _timeCrossesMidnight(String start, String end) {
    final startMinute = _minutes(start);
    final endMinute = _minutes(end);
    if (startMinute < 0 || endMinute < 0) return false;
    return endMinute < startMinute;
  }

  static int _minutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return -1;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return -1;
    return hour * 60 + minute;
  }
}

class AttendanceWindowResult {
  final bool allowed;
  final String status;
  final String message;
  final bool earlyOut;

  const AttendanceWindowResult({
    required this.allowed,
    required this.status,
    required this.message,
    this.earlyOut = false,
  });
}

class _ScheduleContext {
  final AppSession session;
  final String groupId;

  const _ScheduleContext({required this.session, required this.groupId});

  String get companyId => session.companyId;
  String get uid => session.uid;
}

class ScheduleService {
  final RtdbService _rtdb = RtdbService();

  Future<DailySchedule> resolveToday(AppSession session, {DateTime? now}) {
    return resolveForDate(session, now ?? DateTime.now());
  }

  Future<List<DailySchedule>> resolveRange(AppSession session, DateTime start, DateTime end) async {
    final from = DateTime(start.year, start.month, start.day);
    final to = DateTime(end.year, end.month, end.day);
    final rows = <DailySchedule>[];
    var current = from;
    while (!current.isAfter(to)) {
      rows.add(await resolveForDate(session, current));
      current = current.add(const Duration(days: 1));
    }
    return rows;
  }

  Future<DailySchedule> resolveForDate(AppSession session, DateTime dateTime) async {
    final date = AppDate.dateKey(dateTime);
    final companyUser = await _rtdb.getMap(FirebasePaths.companyUser(session.companyId, session.uid));
    final context = _ScheduleContext(
      session: session,
      groupId: asString(companyUser?['group_id'], session.groupId),
    );

    final holiday = await _rtdb.getMap(FirebasePaths.holiday(context.companyId, date));
    final isHoliday = holiday != null && _isActive(holiday);

    final overtime = await _findOvertimeSchedule(context, date);
    if (overtime != null) {
      return DailySchedule.overtime(
        item: overtime,
        scheduleId: asString(overtime['id']),
        date: date,
        holidayWork: isHoliday,
      );
    }

    final special = await _findSpecialSchedule(context, date);
    if (special != null) {
      return _resolveShift(
        context: context,
        shiftId: asString(special['shift_id']),
        dateTime: dateTime,
        source: 'special_schedule',
        assignmentId: asString(special['id']),
        assignmentStartDate: asString(special['date']),
        assignmentEndDate: asString(special['date']),
      );
    }

    if (isHoliday) {
      final title = asString(holiday['title'], 'Hari libur');
      return DailySchedule.holiday(title);
    }

    final assignment = await _findAssignment(context, date);
    if (assignment == null) {
      return DailySchedule.off('Jadwal kerja belum diatur untuk hari ini.');
    }

    final source = asString(assignment['type']) == 'user' ? 'user_assignment' : 'group_assignment';
    return _resolveShift(
      context: context,
      shiftId: asString(assignment['shift_id']),
      dateTime: dateTime,
      source: source,
      assignmentId: asString(assignment['id']),
      assignmentStartDate: asString(assignment['start_date']),
      assignmentEndDate: asString(assignment['end_date']),
    );
  }

  Future<Map<String, dynamic>?> _findOvertimeSchedule(_ScheduleContext context, String date) async {
    final root = await _rtdb.getMap(FirebasePaths.overtimeSchedules(context.companyId));
    if (root == null || root.isEmpty) return null;

    final matches = <Map<String, dynamic>>[];
    for (final entry in root.entries) {
      final item = asMap(entry.value);
      if (!_isActive(item)) continue;
      final status = asString(item['status'], 'active').toLowerCase();
      if (status == 'inactive' || status == 'disabled') continue;
      if (!_dateMatchesOvertime(item, date)) continue;
      final targets = asMap(item['target_uids']);
      if (!_targetMatches(targets, context.uid)) continue;
      item['id'] = asString(item['schedule_id'], entry.key);
      matches.add(item);
    }

    if (matches.isEmpty) return null;
    matches.sort((a, b) => asInt(b['updated_at'], asInt(b['created_at'])).compareTo(asInt(a['updated_at'], asInt(a['created_at']))));
    return matches.first;
  }

  bool _dateMatchesOvertime(Map<String, dynamic> item, String date) {
    final dates = asMap(item['dates']);
    if (dates.isNotEmpty) return dates[date] == true || asString(dates[date]) == 'true';
    final directDate = asString(item['date']);
    if (directDate.isNotEmpty) return directDate == date;
    return _dateInRange(date, asString(item['date_start']), asString(item['date_end']));
  }

  bool _targetMatches(Map<String, dynamic> targets, String uid) {
    if (targets.isEmpty) return false;
    return targets[uid] == true || asString(targets[uid]) == 'true';
  }

  Future<Map<String, dynamic>?> _findSpecialSchedule(_ScheduleContext context, String date) async {
    final specials = await _rtdb.getMap(FirebasePaths.scheduleSpecials(context.companyId));
    if (specials == null || specials.isEmpty) return null;

    final matches = <Map<String, dynamic>>[];
    for (final entry in specials.entries) {
      final item = asMap(entry.value);
      if (!_isActive(item)) continue;
      if (asString(item['date']) != date) continue;

      final type = asString(item['type']);
      final targetId = asString(item['target_id']);
      final userMatch = type == 'user' && targetId == context.uid;
      final groupMatch = type == 'group' && targetId.isNotEmpty && targetId == context.groupId;
      if (userMatch || groupMatch) {
        item['id'] = asString(item['id'], entry.key);
        matches.add(item);
      }
    }

    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final aUser = asString(a['type']) == 'user' ? 1 : 0;
      final bUser = asString(b['type']) == 'user' ? 1 : 0;
      if (aUser != bUser) return bUser.compareTo(aUser);
      return asInt(b['created_at']).compareTo(asInt(a['created_at']));
    });
    return matches.first;
  }

  Future<Map<String, dynamic>?> _findAssignment(_ScheduleContext context, String date) async {
    final assignments = await _rtdb.getMap(FirebasePaths.scheduleAssignments(context.companyId));
    if (assignments == null || assignments.isEmpty) return null;

    final matches = <Map<String, dynamic>>[];
    for (final entry in assignments.entries) {
      final item = asMap(entry.value);
      if (!_isActive(item)) continue;
      if (!_dateInRange(date, asString(item['start_date']), asString(item['end_date']))) continue;

      final type = asString(item['type']);
      final targetId = asString(item['target_id']);
      final userMatch = type == 'user' && targetId == context.uid;
      final groupMatch = type == 'group' && targetId.isNotEmpty && targetId == context.groupId;
      if (userMatch || groupMatch) {
        item['id'] = asString(item['id'], entry.key);
        matches.add(item);
      }
    }

    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final aUser = asString(a['type']) == 'user' ? 1 : 0;
      final bUser = asString(b['type']) == 'user' ? 1 : 0;
      if (aUser != bUser) return bUser.compareTo(aUser);
      return asString(b['start_date']).compareTo(asString(a['start_date']));
    });
    return matches.first;
  }

  Future<DailySchedule> _resolveShift({
    required _ScheduleContext context,
    required String shiftId,
    required DateTime dateTime,
    required String source,
    required String assignmentId,
    String assignmentStartDate = '',
    String assignmentEndDate = '',
  }) async {
    if (shiftId.isEmpty) {
      return DailySchedule.off('Shift belum dipilih.', source: source, assignmentId: assignmentId, assignmentStartDate: assignmentStartDate, assignmentEndDate: assignmentEndDate, scheduleReady: false);
    }

    final shift = await _rtdb.getMap(FirebasePaths.shift(context.companyId, shiftId));
    if (shift == null || !_isActive(shift)) {
      return DailySchedule.off('Shift tidak aktif atau tidak ditemukan.', source: source, assignmentId: assignmentId, assignmentStartDate: assignmentStartDate, assignmentEndDate: assignmentEndDate, shiftId: shiftId, scheduleReady: false);
    }

    final dayKey = _weekdayKey(dateTime);
    final days = asMap(shift['days']);
    final day = asMap(days[dayKey]);
    if (!_isActive(day)) {
      return DailySchedule.off(
        'Hari ini bukan hari kerja pada shift ${asString(shift['name'], shiftId)}.',
        source: source,
        assignmentId: assignmentId,
        assignmentStartDate: assignmentStartDate,
        assignmentEndDate: assignmentEndDate,
        shiftId: shiftId,
        shiftName: asString(shift['name']),
        scheduleReady: true,
      );
    }

    final timetableId = asString(day['timetable_id']);
    if (timetableId.isEmpty) {
      return DailySchedule.off('Timetable belum dipilih untuk hari ini.', source: source, assignmentId: assignmentId, assignmentStartDate: assignmentStartDate, assignmentEndDate: assignmentEndDate, shiftId: shiftId, shiftName: asString(shift['name']), scheduleReady: true);
    }

    final timetable = await _rtdb.getMap(FirebasePaths.timetable(context.companyId, timetableId));
    if (timetable == null || !_isActive(timetable)) {
      return DailySchedule.off('Jam kerja tidak aktif atau tidak ditemukan.', source: source, assignmentId: assignmentId, assignmentStartDate: assignmentStartDate, assignmentEndDate: assignmentEndDate, shiftId: shiftId, shiftName: asString(shift['name']), scheduleReady: false);
    }

    return DailySchedule(
      scheduleReady: true,
      isWorkday: true,
      isHoliday: false,
      message: 'Jadwal tersedia.',
      source: source,
      assignmentId: assignmentId,
      assignmentStartDate: assignmentStartDate,
      assignmentEndDate: assignmentEndDate,
      shiftId: shiftId,
      shiftName: asString(shift['name']),
      timetableId: timetableId,
      timetableName: asString(timetable['name']),
      workStart: asString(timetable['work_start']),
      workEnd: asString(timetable['work_end']),
      checkInStart: asString(timetable['check_in_start']),
      checkInEnd: asString(timetable['check_in_end']),
      checkOutStart: asString(timetable['check_out_start']),
      checkOutEnd: asString(timetable['check_out_end']),
      lateToleranceMinute: asInt(timetable['late_tolerance_minute']),
      earlyOutToleranceMinute: asInt(timetable['early_out_tolerance_minute']),
      crossesMidnight: timetable['crosses_midnight'] == true || asString(timetable['crosses_midnight']) == 'true',
    );
  }

  AttendanceWindowResult validateAction({
    required DailySchedule schedule,
    required String actionType,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    if (schedule.isHoliday) {
      return AttendanceWindowResult(allowed: false, status: 'libur', message: 'Hari ini libur: ${schedule.message}');
    }
    if (!schedule.isWorkday) {
      return AttendanceWindowResult(allowed: false, status: 'no_schedule', message: schedule.message);
    }

    if (actionType == 'masuk') {
      final inWindow = _isTimeInWindow(current, schedule.checkInStart, schedule.checkInEnd);
      if (!inWindow) {
        return AttendanceWindowResult(
          allowed: false,
          status: 'outside_check_in_window',
          message: 'Absen masuk hanya dapat dilakukan pukul ${schedule.checkInStart} - ${schedule.checkInEnd}.',
        );
      }

      final lateLimit = _minutesOfDay(schedule.workStart) + schedule.lateToleranceMinute;
      final nowMinute = current.hour * 60 + current.minute;
      final isLate = lateLimit >= 0 && nowMinute > lateLimit;
      return AttendanceWindowResult(
        allowed: true,
        status: isLate ? 'terlambat' : 'hadir',
        message: isLate ? 'Terlambat' : 'Tepat waktu',
      );
    }

    if (actionType == 'pulang') {
      final inWindow = _isTimeInWindow(current, schedule.checkOutStart, schedule.checkOutEnd);
      if (!inWindow) {
        return AttendanceWindowResult(
          allowed: false,
          status: 'outside_check_out_window',
          message: 'Absen pulang hanya dapat dilakukan pukul ${schedule.checkOutStart} - ${schedule.checkOutEnd}.',
        );
      }

      final earlyLimit = _minutesOfDay(schedule.workEnd) - schedule.earlyOutToleranceMinute;
      final nowMinute = current.hour * 60 + current.minute;
      final isEarly = !schedule.crossesMidnight && earlyLimit >= 0 && nowMinute < earlyLimit;
      return AttendanceWindowResult(
        allowed: true,
        status: 'hadir',
        message: isEarly ? 'Pulang awal' : 'Sesuai jadwal',
        earlyOut: isEarly,
      );
    }

    return const AttendanceWindowResult(allowed: true, status: 'hadir', message: 'Valid');
  }

  bool _isActive(Map<String, dynamic> data) {
    final value = data['active'];
    if (value == null) return true;
    if (value is bool) return value;
    return value.toString() == 'true';
  }

  bool _dateInRange(String date, String startDate, String endDate) {
    if (startDate.isEmpty && endDate.isEmpty) return false;
    if (startDate.isNotEmpty && date.compareTo(startDate) < 0) return false;
    if (endDate.isNotEmpty && date.compareTo(endDate) > 0) return false;
    return true;
  }

  String _weekdayKey(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday';
    }
    return 'monday';
  }

  bool _isTimeInWindow(DateTime dateTime, String start, String end) {
    final startMinute = _minutesOfDay(start);
    final endMinute = _minutesOfDay(end);
    final current = dateTime.hour * 60 + dateTime.minute;

    if (startMinute < 0 || endMinute < 0) return true;
    if (startMinute <= endMinute) return current >= startMinute && current <= endMinute;
    return current >= startMinute || current <= endMinute;
  }

  int _minutesOfDay(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return -1;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return -1;
    return hour * 60 + minute;
  }
}
