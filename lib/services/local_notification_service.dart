import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel highImportanceChannel =
      AndroidNotificationChannel(
    'mypresence_high_importance_channel',
    'MYPRESENCE Notifications',
    description: 'Notifikasi penting MYPRESENCE',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static bool _timezoneReady = false;
  static bool _initialized = false;
  static void Function(Map<String, dynamic> payload)? _onTap;

  static Future<void> initialize({
    required void Function(Map<String, dynamic> payload) onTap,
  }) async {
    _onTap = onTap;
    _ensureTimezone();

    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('ic_notification');
    const initSettings = InitializationSettings(android: androidSettings);

    await plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map) {
            _onTap?.call(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {}
      },
    );

    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(highImportanceChannel);
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic> payload = const {},
  }) async {
    final details = _notificationDetails();

    await plugin.show(
      id,
      title,
      body,
      details,
      payload: jsonEncode(payload),
    );
  }

  static Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    Map<String, dynamic> payload = const {},
  }) async {
    _ensureTimezone();
    if (!scheduledAt.isAfter(DateTime.now())) return;

    await plugin.zonedSchedule(
      id,
      title,
      body,
      _scheduledDate(scheduledAt),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode(payload),
    );
  }

  static Future<void> cancel(int id) => plugin.cancel(id);

  static NotificationDetails _notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        highImportanceChannel.id,
        highImportanceChannel.name,
        channelDescription: highImportanceChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      ),
    );
  }

  static tz.TZDateTime _scheduledDate(DateTime dateTime) {
    final local = tz.local;
    return tz.TZDateTime(
      local,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
      dateTime.microsecond,
    );
  }

  static void _ensureTimezone() {
    if (_timezoneReady) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    _timezoneReady = true;
  }
}
