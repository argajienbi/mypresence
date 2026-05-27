import '../core/models/app_session.dart';
import 'local_notification_service.dart';
import 'schedule_service.dart';

class AttendanceReminderService {
  AttendanceReminderService._();

  static const int _checkInBaseId = 710100;
  static const int _checkOutBaseId = 710200;

  static Future<void> scheduleToday({
    required AppSession session,
    required DailySchedule? schedule,
    required bool hasIn,
    required bool hasOut,
  }) async {
    final now = DateTime.now();
    final dateKey = '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final daySeed = int.tryParse(dateKey) ?? now.day;
    final checkInId = _checkInBaseId + (daySeed % 10000);
    final checkOutId = _checkOutBaseId + (daySeed % 10000);

    await LocalNotificationService.cancel(checkInId);
    await LocalNotificationService.cancel(checkOutId);

    if (schedule == null || !schedule.isWorkday || schedule.isHoliday) return;

    if (!hasIn) {
      final workStart = _todayAt(schedule.workStart.isNotEmpty ? schedule.workStart : schedule.checkInStart);
      if (workStart != null) {
        final reminderAt = workStart.subtract(const Duration(minutes: 10));
        if (reminderAt.isAfter(now)) {
          final body = 'Jadwal kerja Anda dimulai pukul ${_shortTime(workStart)}.';
          await LocalNotificationService.scheduleOnce(
            id: checkInId,
            title: 'Jangan lupa absen masuk',
            body: body,
            scheduledAt: reminderAt,
            payload: {
              'ref_type': 'attendance_reminder',
              'type': 'reminder',
              'title': 'Jangan lupa absen masuk',
              'body': body,
            },
          );
        }
      }
    }

    if (!hasOut) {
      final workEnd = _todayAt(schedule.workEnd.isNotEmpty ? schedule.workEnd : schedule.checkOutEnd);
      final adjustedEnd = schedule.crossesMidnight && workEnd != null && workEnd.isBefore(now)
          ? workEnd.add(const Duration(days: 1))
          : workEnd;
      if (adjustedEnd != null) {
        final reminderAt = adjustedEnd.subtract(const Duration(minutes: 10));
        if (reminderAt.isAfter(now)) {
          await LocalNotificationService.scheduleOnce(
            id: checkOutId,
            title: 'Jangan lupa absen pulang',
            body: 'Jangan lupa melakukan Check-Out sebelum pulang.',
            scheduledAt: reminderAt,
            payload: {
              'ref_type': 'attendance_reminder',
              'type': 'reminder',
              'title': 'Jangan lupa absen pulang',
              'body': 'Jangan lupa melakukan Check-Out sebelum pulang.',
            },
          );
        }
      }
    }
  }

  static DateTime? _todayAt(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  static String _shortTime(DateTime value) => '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
