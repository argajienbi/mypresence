import 'package:firebase_database/firebase_database.dart';

import '../core/models/app_session.dart';
import '../core/utils.dart';
import 'local_notification_service.dart';
import 'schedule_service.dart';

class AttendanceReminderService {
  AttendanceReminderService._();

  static const int _checkInBaseId = 710100;
  static const int _checkOutBaseId = 710200;
  static const Duration _lateReminderGrace = Duration(minutes: 15);
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  static Future<void> scheduleToday({
    required AppSession session,
    required DailySchedule? schedule,
    required bool hasIn,
    required bool hasOut,
    required bool hasApprovedLeave,
  }) async {
    final now = DateTime.now();
    final dayKey = AppDate.dateKey(now);
    final daySeed = int.tryParse(dayKey.replaceAll('-', '')) ?? now.day;

    if (schedule == null || !schedule.isWorkday || schedule.isHoliday || hasApprovedLeave) {
      await _clearReminderGroup(session, dayKey, daySeed, 'check_in');
      await _clearReminderGroup(session, dayKey, daySeed, 'check_out');
      return;
    }

    if (!hasIn) {
      final workStart = _todayAt(
        schedule.workStart.isNotEmpty ? schedule.workStart : schedule.checkInStart,
      );
      if (workStart != null) {
        await _scheduleReminder(
          session: session,
          dayKey: dayKey,
          daySeed: daySeed,
          action: 'check_in',
          stage: 'pre',
          title: 'Jangan lupa absen masuk',
          body: 'Jadwal kerja Anda dimulai pukul ${_shortTime(workStart)}.',
          scheduledAt: workStart.subtract(const Duration(minutes: 10)),
          catchUpUntil: workStart,
        );
        await _scheduleReminder(
          session: session,
          dayKey: dayKey,
          daySeed: daySeed,
          action: 'check_in',
          stage: 'now',
          title: 'Waktunya absen masuk',
          body: 'Silakan absen masuk sesuai jadwal hari ini.',
          scheduledAt: workStart,
        );
      }
    } else {
      await _clearReminderGroup(session, dayKey, daySeed, 'check_in');
    }

    if (!hasOut) {
      final workEnd = _todayAt(
        schedule.workEnd.isNotEmpty ? schedule.workEnd : schedule.checkOutEnd,
      );
      final adjustedEnd = schedule.crossesMidnight &&
              workEnd != null &&
              workEnd.isBefore(now)
          ? workEnd.add(const Duration(days: 1))
          : workEnd;
      if (adjustedEnd != null) {
        await _scheduleReminder(
          session: session,
          dayKey: dayKey,
          daySeed: daySeed,
          action: 'check_out',
          stage: 'pre',
          title: 'Jangan lupa absen pulang',
          body: 'Jangan lupa melakukan Clock Out sebelum jam selesai.',
          scheduledAt: adjustedEnd.subtract(const Duration(minutes: 10)),
          catchUpUntil: adjustedEnd,
        );
        await _scheduleReminder(
          session: session,
          dayKey: dayKey,
          daySeed: daySeed,
          action: 'check_out',
          stage: 'now',
          title: 'Waktunya absen pulang',
          body: 'Silakan absen pulang sesuai jadwal hari ini.',
          scheduledAt: adjustedEnd,
        );
      }
    } else {
      await _clearReminderGroup(session, dayKey, daySeed, 'check_out');
    }
  }

  static Future<void> _scheduleReminder({
    required AppSession session,
    required String dayKey,
    required int daySeed,
    required String action,
    required String stage,
    required String title,
    required String body,
    required DateTime scheduledAt,
    DateTime? catchUpUntil,
  }) async {
    final localNotificationId = _scheduledNotificationId(daySeed, action, stage);
    final payload = _payload(
      dateKey: dayKey,
      action: action,
      stage: stage,
      title: title,
      body: body,
      scheduledAt: scheduledAt,
    );
    final reminderId = payload['notification_id'].toString();
    final now = DateTime.now();

    if (scheduledAt.isAfter(now)) {
      await _upsertReminderInbox(session, payload);
      await LocalNotificationService.scheduleOnce(
        id: localNotificationId,
        title: payload['title'].toString(),
        body: payload['body'].toString(),
        scheduledAt: scheduledAt,
        payload: payload,
      );
      return;
    }

    if (catchUpUntil != null && now.isAfter(catchUpUntil)) {
      return;
    }

    await _upsertReminderInbox(session, payload);

    if (now.difference(scheduledAt) > _lateReminderGrace) {
      return;
    }

    if (await _wasLocallyDelivered(session, reminderId)) {
      return;
    }

    await LocalNotificationService.show(
      id: localNotificationId,
      title: payload['title'].toString(),
      body: payload['body'].toString(),
      payload: payload,
    );
    await _markLocallyDelivered(session, reminderId);
  }

  static Map<String, dynamic> _payload({
    required String dateKey,
    required String action,
    required String stage,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) {
    final id = _reminderId(dateKey, action, stage);
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
      'reminder_stage': stage,
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
    final ref = _database.ref('notifications/${session.uid}/$id');
    final existing = await ref.get();
    final existingValue = existing.value;
    final existingRead = existingValue is Map
        ? _asBool(existingValue['read']) || _asBool(existingValue['is_read'])
        : false;
    final existingReadAt = existingValue is Map
        ? existingValue['read_at'] ?? existingValue['readAt']
        : null;

    await ref.set({
      ...payload,
      'read': existingRead,
      'is_read': existingRead,
      if (existingReadAt != null) 'read_at': existingReadAt,
      'company_id': session.companyId,
      'uid': session.uid,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }).catchError((_) {});
  }

  static Future<void> _clearReminderGroup(
    AppSession session,
    String dayKey,
    int daySeed,
    String action,
  ) async {
    for (final stage in const ['pre', 'now']) {
      await _clearReminderEntry(session, dayKey, daySeed, action, stage);
    }
  }

  static Future<void> _clearReminderEntry(
    AppSession session,
    String dayKey,
    int daySeed,
    String action,
    String stage,
  ) async {
    final id = _reminderId(dayKey, action, stage);
    await LocalNotificationService.cancel(
      _scheduledNotificationId(daySeed, action, stage),
    );
    await _database.ref('notifications/${session.uid}/$id').update({
      'read': true,
      'is_read': true,
      'active': false,
      'cleared_at': DateTime.now().millisecondsSinceEpoch,
    }).catchError((_) {});
  }

  static Future<bool> _wasLocallyDelivered(
    AppSession session,
    String id,
  ) async {
    final snap = await _database.ref('notifications/${session.uid}/$id').get();
    final value = snap.value;
    if (value is! Map) return false;
    return value['local_delivered_at'] != null ||
        value['local_shown_at'] != null;
  }

  static Future<void> _markLocallyDelivered(
    AppSession session,
    String id,
  ) async {
    await _database.ref('notifications/${session.uid}/$id').update({
      'local_delivered_at': DateTime.now().millisecondsSinceEpoch,
      'local_delivery_mode': 'catch_up',
    }).catchError((_) {});
  }

  static String _reminderId(String dateKey, String action, String stage) =>
      'attendance_reminder_${dateKey}_${action}_$stage';

  static int _scheduledNotificationId(
    int daySeed,
    String action,
    String stage,
  ) {
    final base = action == 'check_in' ? _checkInBaseId : _checkOutBaseId;
    final variant = stage == 'now' ? 1 : 0;
    return base + (daySeed % 10000) * 10 + variant;
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

  static String _shortTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  static bool _asBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }
}
