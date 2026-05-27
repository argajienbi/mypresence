import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
    'mypresensi_high_importance_channel',
    'MYPRESENSI Notifications',
    description: 'Notifikasi penting MYPRESENSI',
    importance: Importance.high,
  );

  static bool _timezoneReady = false;

  static Future<void> initialize({
    required void Function(Map<String, dynamic> payload) onTap,
  }) async {
    _ensureTimezone();

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const initSettings = InitializationSettings(android: androidSettings);

    await plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) onTap(decoded);
        } catch (_) {}
      },
    );

    final androidPlugin = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(highImportanceChannel);
    await androidPlugin?.requestNotificationsPermission();
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
      tz.TZDateTime.from(scheduledAt, tz.local),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
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
        icon: '@drawable/ic_notification',
      ),
    );
  }

  static void _ensureTimezone() {
    if (_timezoneReady) return;
    tz_data.initializeTimeZones();
    _timezoneReady = true;
  }
}
