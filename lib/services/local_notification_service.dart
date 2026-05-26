import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel highImportanceChannel =
      AndroidNotificationChannel(
    'mypresensi_high_importance_channel',
    'MYPRESENSI Notifications',
    description: 'Notifikasi penting MYPRESENSI',
    importance: Importance.high,
  );

  static Future<void> initialize({
    required void Function(Map<String, dynamic> payload) onTap,
  }) async {
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

    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(highImportanceChannel);
    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic> payload = const {},
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        highImportanceChannel.id,
        highImportanceChannel.name,
        channelDescription: highImportanceChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
      ),
    );

    await plugin.show(
      id,
      title,
      body,
      details,
      payload: jsonEncode(payload),
    );
  }
}
