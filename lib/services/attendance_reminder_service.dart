import 'package:firebase_database/firebase_database.dart';

import '../core/models/app_session.dart';
import '../core/utils.dart';
import 'local_notification_service.dart';
import 'notification_service.dart';
import 'schedule_service.dart';

class AttendanceReminderService {
  AttendanceReminderService._();

  static const int _checkInBaseId = 710100;
  static const int _checkOutBaseId = 710200;
  static const String _settingsSource = 'companies_notification_settings';
  static const int _configVersion = 1;
  static final NotificationService _notificationService =
      NotificationService();
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  static Future<void> scheduleToday({
    required AppSession session,
    required DailySchedule? schedule,
    required bool hasIn,
    required bool hasOut,
    required bool hasApprovedLeave,
  }) async {
    final settings = await _loadSettings(session);
    final now = DateTime.now();
    final dayKey = AppDate.dateKey(now);
    final daySeed = int.tryParse(dayKey.replaceAll('-', '')) ?? now.day;

    if (!settings.attendanceReminderEnabled) {
      await _clearAllReminderGroups(session, dayKey, daySeed);
      return;
    }

    if (schedule == null ||
        !schedule.isWorkday ||
        schedule.isHoliday ||
        hasApprovedLeave) {
      await _clearAllReminderGroups(session, dayKey, daySeed);
      return;
    }

    if (hasIn) {
      await _clearReminderGroup(session, dayKey, daySeed, 'check_in');
    } else {
      final workStart = _todayAt(
        schedule.workStart.isNotEmpty ? schedule.workStart : schedule.checkInStart,
      );
      if (workStart == null) {
        await _clearReminderGroup(session, dayKey, daySeed, 'check_in');
      } else {
        await _syncReminderAction(
          session: session,
          dayKey: dayKey,
          daySeed: daySeed,
          action: 'check_in',
          anchor: workStart,
          preEnabled: settings.checkInPreEnabled,
          preMinutes: settings.checkInPreMinutes,
          nowEnabled: settings.checkInNowEnabled,
          lateEnabled: settings.checkInLateEnabled,
          lateMinutes: settings.checkInLateMinutes,
          catchUpMinutes: settings.schedulerCatchUpMinutes,
          preTitle: 'Jangan lupa absen masuk',
          preBody: 'Jadwal kerja Anda dimulai pukul ${_shortTime(workStart)}.',
          nowTitle: 'Waktunya absen masuk',
          nowBody: 'Silakan absen masuk sesuai jadwal hari ini.',
          lateTitle: 'Absen masuk belum dilakukan',
          lateBody: 'Anda belum absen masuk. Segera lakukan presensi.',
        );
      }
    }

    if (hasOut) {
      await _clearReminderGroup(session, dayKey, daySeed, 'check_out');
    } else {
      final workEnd = _todayAt(
        schedule.workEnd.isNotEmpty ? schedule.workEnd : schedule.checkOutEnd,
      );
      final adjustedEnd = schedule.crossesMidnight &&
              workEnd != null &&
              workEnd.isBefore(now)
          ? workEnd.add(const Duration(days: 1))
          : workEnd;
      if (adjustedEnd == null) {
        await _clearReminderGroup(session, dayKey, daySeed, 'check_out');
      } else {
        await _syncReminderAction(
          session: session,
          dayKey: dayKey,
          daySeed: daySeed,
          action: 'check_out',
          anchor: adjustedEnd,
          preEnabled: settings.checkOutPreEnabled,
          preMinutes: settings.checkOutPreMinutes,
          nowEnabled: settings.checkOutNowEnabled,
          lateEnabled: settings.checkOutLateEnabled,
          lateMinutes: settings.checkOutLateMinutes,
          catchUpMinutes: settings.schedulerCatchUpMinutes,
          preTitle: 'Jangan lupa absen pulang',
          preBody: 'Jangan lupa melakukan Clock Out sebelum jam selesai.',
          nowTitle: 'Waktunya absen pulang',
          nowBody: 'Silakan absen pulang sesuai jadwal hari ini.',
          lateTitle: 'Absen pulang belum dilakukan',
          lateBody: 'Anda belum absen pulang. Segera lakukan Clock Out.',
        );
      }
    }
  }

  static Future<void> _syncReminderAction({
    required AppSession session,
    required String dayKey,
    required int daySeed,
    required String action,
    required DateTime anchor,
    required bool preEnabled,
    required int preMinutes,
    required bool nowEnabled,
    required bool lateEnabled,
    required int lateMinutes,
    required int catchUpMinutes,
    required String preTitle,
    required String preBody,
    required String nowTitle,
    required String nowBody,
    required String lateTitle,
    required String lateBody,
  }) async {
    await _syncReminderStage(
      session: session,
      dayKey: dayKey,
      daySeed: daySeed,
      action: action,
      stage: 'pre',
      enabled: preEnabled,
      scheduledAt: anchor.subtract(Duration(minutes: preMinutes)),
      catchUpMinutes: catchUpMinutes,
      title: preTitle,
      body: preBody,
    );
    await _syncReminderStage(
      session: session,
      dayKey: dayKey,
      daySeed: daySeed,
      action: action,
      stage: 'now',
      enabled: nowEnabled,
      scheduledAt: anchor,
      catchUpMinutes: catchUpMinutes,
      title: nowTitle,
      body: nowBody,
    );
    await _syncReminderStage(
      session: session,
      dayKey: dayKey,
      daySeed: daySeed,
      action: action,
      stage: 'late',
      enabled: lateEnabled,
      scheduledAt: anchor.add(Duration(minutes: lateMinutes)),
      catchUpMinutes: catchUpMinutes,
      title: lateTitle,
      body: lateBody,
    );
  }

  static Future<void> _syncReminderStage({
    required AppSession session,
    required String dayKey,
    required int daySeed,
    required String action,
    required String stage,
    required bool enabled,
    required DateTime scheduledAt,
    required int catchUpMinutes,
    required String title,
    required String body,
  }) async {
    if (!enabled) {
      await _clearReminderEntry(session, dayKey, daySeed, action, stage);
      return;
    }

    await _scheduleReminder(
      session: session,
      dayKey: dayKey,
      daySeed: daySeed,
      action: action,
      stage: stage,
      title: title,
      body: body,
      scheduledAt: scheduledAt,
      catchUpMinutes: catchUpMinutes,
    );
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
    required int catchUpMinutes,
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

    await _upsertReminderInbox(session, payload);

    if (scheduledAt.isAfter(now)) {
      await LocalNotificationService.scheduleOnce(
        id: localNotificationId,
        title: payload['title'].toString(),
        body: payload['body'].toString(),
        scheduledAt: scheduledAt,
        payload: payload,
      );
      return;
    }

    if (now.difference(scheduledAt) >
        Duration(minutes: catchUpMinutes)) {
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
      'settings_source': _settingsSource,
      'reminder_config_version': _configVersion,
      'source': 'local_attendance_reminder',
    };
  }

  static Future<void> _upsertReminderInbox(
    AppSession session,
    Map<String, dynamic> payload,
  ) async {
    await _notificationService.upsertPayload(
      session: session,
      payload: {
        ...payload,
        'company_id': session.companyId,
        'uid': session.uid,
      },
      preserveActiveState: false,
    );
  }

  static Future<void> _clearReminderGroup(
    AppSession session,
    String dayKey,
    int daySeed,
    String action,
  ) async {
    for (final stage in const ['pre', 'now', 'late']) {
      await _clearReminderEntry(session, dayKey, daySeed, action, stage);
    }
  }

  static Future<void> _clearAllReminderGroups(
    AppSession session,
    String dayKey,
    int daySeed,
  ) async {
    await _clearReminderGroup(session, dayKey, daySeed, 'check_in');
    await _clearReminderGroup(session, dayKey, daySeed, 'check_out');
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
    final now = DateTime.now().millisecondsSinceEpoch;
    await _notificationService.updateNotificationFields(
      session: session,
      notificationId: id,
      fields: {
        'read': true,
        'is_read': true,
        'active': false,
        'cleared_at': now,
      },
    );
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

  static Future<void> cancelScheduledReminderByNotificationId(
    String notificationId,
  ) async {
    final localNotificationId =
        _localNotificationIdFromNotificationId(notificationId);
    if (localNotificationId == null) return;
    await LocalNotificationService.cancel(localNotificationId);
  }

  static String _reminderId(String dateKey, String action, String stage) =>
      'attendance_reminder_${dateKey}_${action}_$stage';

  static int _scheduledNotificationId(
    int daySeed,
    String action,
    String stage,
  ) {
    final base = action == 'check_in' ? _checkInBaseId : _checkOutBaseId;
    final variant = stage == 'now'
        ? 1
        : stage == 'late'
            ? 2
            : 0;
    return base + (daySeed % 10000) * 10 + variant;
  }

  static int? _localNotificationIdFromNotificationId(String notificationId) {
    final match = RegExp(
      r'^attendance_reminder_(\d{4}-\d{2}-\d{2})_(check_in|check_out)_(pre|now|late)$',
    ).firstMatch(notificationId.trim());
    if (match == null) return null;

    final daySeed =
        int.tryParse(match.group(1)!.replaceAll('-', '')) ?? DateTime.now().day;
    return _scheduledNotificationId(
      daySeed,
      match.group(2)!,
      match.group(3)!,
    );
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

  static Future<_AttendanceReminderSettings> _loadSettings(
    AppSession session,
  ) async {
    try {
      final snapshot = await _database
          .ref('companies/${session.companyId}/notification_settings/main')
          .get();
      final data = asMap(snapshot.value);
      if (data.isEmpty) return _AttendanceReminderSettings.defaults();
      return _AttendanceReminderSettings.fromMap(data);
    } catch (_) {
      return _AttendanceReminderSettings.defaults();
    }
  }

  static bool _readBool(
    Map<String, dynamic> data,
    List<String> keys,
    bool fallback,
  ) {
    for (final key in keys) {
      if (!data.containsKey(key)) continue;
      final value = data[key];
      if (value == null) continue;
      if (value is bool) return value;
      if (value is num) return value != 0;
      final text = value.toString().trim().toLowerCase();
      if (text.isEmpty) continue;
      if (text == 'true' || text == '1' || text == 'yes' || text == 'y') {
        return true;
      }
      if (text == 'false' || text == '0' || text == 'no' || text == 'n') {
        return false;
      }
    }
    return fallback;
  }

  static int _readInt(
    Map<String, dynamic> data,
    List<String> keys,
    int fallback, {
    required int min,
    required int max,
  }) {
    for (final key in keys) {
      if (!data.containsKey(key)) continue;
      final value = data[key];
      final parsed = _parseInt(value);
      if (parsed == null) continue;
      return _clampInt(parsed, min, max);
    }
    return _clampInt(fallback, min, max);
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is bool) return value ? 1 : 0;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  static int _clampInt(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}

class _AttendanceReminderSettings {
  final bool attendanceReminderEnabled;
  final bool checkInPreEnabled;
  final bool checkInNowEnabled;
  final bool checkInLateEnabled;
  final bool checkOutPreEnabled;
  final bool checkOutNowEnabled;
  final bool checkOutLateEnabled;
  final int checkInPreMinutes;
  final int checkInNowWindowMinutes;
  final int checkInLateMinutes;
  final int checkOutPreMinutes;
  final int checkOutNowWindowMinutes;
  final int checkOutLateMinutes;
  final int schedulerCatchUpMinutes;

  const _AttendanceReminderSettings({
    required this.attendanceReminderEnabled,
    required this.checkInPreEnabled,
    required this.checkInNowEnabled,
    required this.checkInLateEnabled,
    required this.checkOutPreEnabled,
    required this.checkOutNowEnabled,
    required this.checkOutLateEnabled,
    required this.checkInPreMinutes,
    required this.checkInNowWindowMinutes,
    required this.checkInLateMinutes,
    required this.checkOutPreMinutes,
    required this.checkOutNowWindowMinutes,
    required this.checkOutLateMinutes,
    required this.schedulerCatchUpMinutes,
  });

  factory _AttendanceReminderSettings.defaults() {
    return const _AttendanceReminderSettings(
      attendanceReminderEnabled: true,
      checkInPreEnabled: true,
      checkInNowEnabled: true,
      checkInLateEnabled: false,
      checkOutPreEnabled: true,
      checkOutNowEnabled: true,
      checkOutLateEnabled: false,
      checkInPreMinutes: 10,
      checkInNowWindowMinutes: 6,
      checkInLateMinutes: 10,
      checkOutPreMinutes: 10,
      checkOutNowWindowMinutes: 6,
      checkOutLateMinutes: 10,
      schedulerCatchUpMinutes: 6,
    );
  }

  factory _AttendanceReminderSettings.fromMap(Map<String, dynamic> data) {
    return _AttendanceReminderSettings(
      attendanceReminderEnabled: AttendanceReminderService._readBool(
        data,
        const ['attendance_reminder_enabled'],
        true,
      ),
      checkInPreEnabled: AttendanceReminderService._readBool(
        data,
        const ['reminder_check_in_pre_enabled', 'pre_check_in_enabled'],
        true,
      ),
      checkInNowEnabled: AttendanceReminderService._readBool(
        data,
        const ['reminder_check_in_now_enabled'],
        true,
      ),
      checkInLateEnabled: AttendanceReminderService._readBool(
        data,
        const ['reminder_check_in_late_enabled', 'missed_check_in_enabled'],
        false,
      ),
      checkOutPreEnabled: AttendanceReminderService._readBool(
        data,
        const ['reminder_check_out_pre_enabled', 'pre_check_out_enabled'],
        true,
      ),
      checkOutNowEnabled: AttendanceReminderService._readBool(
        data,
        const ['reminder_check_out_now_enabled'],
        true,
      ),
      checkOutLateEnabled: AttendanceReminderService._readBool(
        data,
        const ['reminder_check_out_late_enabled', 'missed_check_out_enabled'],
        false,
      ),
      checkInPreMinutes: AttendanceReminderService._readInt(
        data,
        const ['reminder_check_in_pre_minutes', 'pre_check_in_minutes'],
        10,
        min: 0,
        max: 120,
      ),
      checkInNowWindowMinutes: AttendanceReminderService._readInt(
        data,
        const ['reminder_check_in_now_window_minutes'],
        6,
        min: 0,
        max: 30,
      ),
      checkInLateMinutes: AttendanceReminderService._readInt(
        data,
        const ['reminder_check_in_late_minutes', 'missed_check_in_minutes'],
        10,
        min: 1,
        max: 180,
      ),
      checkOutPreMinutes: AttendanceReminderService._readInt(
        data,
        const ['reminder_check_out_pre_minutes', 'pre_check_out_minutes'],
        10,
        min: 0,
        max: 120,
      ),
      checkOutNowWindowMinutes: AttendanceReminderService._readInt(
        data,
        const ['reminder_check_out_now_window_minutes'],
        6,
        min: 0,
        max: 30,
      ),
      checkOutLateMinutes: AttendanceReminderService._readInt(
        data,
        const ['reminder_check_out_late_minutes', 'missed_check_out_minutes'],
        10,
        min: 1,
        max: 240,
      ),
      schedulerCatchUpMinutes: AttendanceReminderService._readInt(
        data,
        const ['reminder_scheduler_catchup_minutes'],
        6,
        min: 5,
        max: 30,
      ),
    );
  }
}
