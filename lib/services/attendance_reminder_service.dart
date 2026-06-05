import 'package:firebase_database/firebase_database.dart';

import '../core/models/app_session.dart';
import '../core/utils.dart';
import 'local_notification_service.dart';
import 'schedule_service.dart';

class AttendanceReminderService {
  AttendanceReminderService._();

  static const int _checkInBaseId = 710100;
  static const int _checkOutBaseId = 710200;
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  static Future<void> scheduleToday({
    required AppSession session,
    required DailySchedule? schedule,
    required bool hasIn,
    required bool hasOut,
  }) async {
    final now = DateTime.now();
    final dayKey = AppDate.dateKey(now);
    final daySeed = int.tryParse(dayKey.replaceAll('-', '')) ?? now.day;
    final checkInId = _checkInBaseId + (daySeed % 10000);
    final checkOutId = _checkOutBaseId + (daySeed % 10000);

    await LocalNotificationService.cancel(checkInId);
    await LocalNotificationService.cancel(checkOutId);

    if (schedule == null || !schedule.isWorkday || schedule.isHoliday) {
      await _clearReminderInbox(session, dayKey, 'check_in');
      await _clearReminderInbox(session, dayKey, 'check_out');
      return;
    }

    if (!hasIn) {
      final workStart = _todayAt(schedule.workStart.isNotEmpty ? schedule.workStart : schedule.checkInStart);
      if (workStart != null) {
        final reminderAt = workStart.subtract(const Duration(minutes: 10));
        if (reminderAt.isAfter(now)) {
          final body = 'Jadwal kerja Anda dimulai pukul ${_shortTime(workStart)}.';
          final payload = _payload(
            dateKey: dayKey,
            action: 'check_in',
            title: 'Jangan lupa absen masuk',
            body: body,
            scheduledAt: reminderAt,
          );
          await _upsertReminderInbox(session, payload);
          await LocalNotificationService.scheduleOnce(
            id: checkInId,
            title: payload['title'].toString(),
            body: payload['body'].toString(),
            scheduledAt: reminderAt,
            payload: payload,
          );
        } else {
          await _clearReminderInbox(session, dayKey, 'check_in');
        }
      }
    } else {
      await _clearReminderInbox(session, dayKey, 'check_in');
    }

    if (!hasOut) {
      final workEnd = _todayAt(schedule.workEnd.isNotEmpty ? schedule.workEnd : schedule.checkOutEnd);
      final adjustedEnd = schedule.crossesMidnight && workEnd != null && workEnd.isBefore(now)
          ? workEnd.add(const Duration(days: 1))
          : workEnd;
      if (adjustedEnd != null) {
        final reminderAt = adjustedEnd.subtract(const Duration(minutes: 10));
        if (reminderAt.isAfter(now)) {
          final body = 'Jangan lupa melakukan Clock Out sebelum pulang.';
          final payload = _payload(
            dateKey: dayKey,
            action: 'check_out',
            title: 'Jangan lupa absen pulang',
            body: body,
            scheduledAt: reminderAt,
          );
          await _upsertReminderInbox(session, payload);
          await LocalNotificationService.scheduleOnce(
            id: checkOutId,
            title: payload['title'].toString(),
            body: payload['body'].toString(),
            scheduledAt: reminderAt,
            payload: payload,
          );
        } else {
          await _clearReminderInbox(session, dayKey, 'check_out');
        }
      }
    } else {
      await _clearReminderInbox(session, dayKey, 'check_out');
    }
  }

  static Map<String, dynamic> _payload({
    required String dateKey,
    required String action,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) {
    final id = _reminderId(dateKey, action);
    return {
      'id': id,
      'notification_id': id,
      'title': title,
      'body': body,
      'message': body,
      'type': 'reminder',
      'ref_type': 'attendance_reminder',
      'ref_id': id,
      'related_id': id,
      'reminder_action': action,
      'created_at': scheduledAt.millisecondsSinceEpoch,
      'scheduled_at': scheduledAt.millisecondsSinceEpoch,
      'created_date': dateKey,
      'created_time': _shortTime(scheduledAt),
      'sender_uid': 'system',
      'sender_name': 'Sistem',
      'sender_role': 'system',
      'read': false,
      'is_read': false,
      'active': true,
      'source': 'local_attendance_reminder',
    };
  }

  static Future<void> _upsertReminderInbox(
    AppSession session,
    Map<String, dynamic> payload,
  ) async {
    final id = payload['notification_id'].toString();
    await _database.ref('notifications/${session.uid}/$id').set({
      ...payload,
      'company_id': session.companyId,
      'uid': session.uid,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }).catchError((_) {});
  }

  static Future<void> _clearReminderInbox(
    AppSession session,
    String dateKey,
    String action,
  ) async {
    final id = _reminderId(dateKey, action);
    await _database.ref('notifications/${session.uid}/$id').update({
      'read': true,
      'is_read': true,
      'active': false,
      'cleared_at': DateTime.now().millisecondsSinceEpoch,
    }).catchError((_) {});
  }

  static String _reminderId(String dateKey, String action) => 'attendance_reminder_${dateKey}_$action';

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
