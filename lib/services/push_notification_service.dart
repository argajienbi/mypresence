import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/firestore_paths.dart';
import '../core/models/app_session.dart';
import 'local_notification_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Map<String, dynamic>? pendingPayload;
  static void Function(Map<String, dynamic> payload)? onPayloadReceived;

  static bool _initialized = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  static Future<void> initialize({
    required void Function(Map<String, dynamic> payload) onNotificationTap,
  }) async {
    if (_initialized) return;
    _initialized = true;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await LocalNotificationService.initialize(
      onTap: handlePayload,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await showForegroundMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final payload = _normalizePayload(message);
      handlePayload(payload);
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      final payload = _normalizePayload(initial);
      handlePayload(payload);
    }
  }

  static Future<void> showForegroundMessage(RemoteMessage message) async {
    final payload = _normalizePayload(message);

    await LocalNotificationService.show(
      id: _notificationId(message),
      title: payload['title'].toString(),
      body: payload['body'].toString(),
      payload: payload,
    );
  }

  static Future<void> showBackgroundMessage(RemoteMessage message) async {
    // Kalau payload FCM berisi notification, Android biasanya sudah menampilkan
    // notifikasi otomatis saat aplikasi background/killed.
    // Jadi local notification hanya ditampilkan untuk data-only message.
    if (message.notification != null) return;

    await LocalNotificationService.initialize(
      onTap: handlePayload,
    );

    final payload = _normalizePayload(message);

    await LocalNotificationService.show(
      id: _notificationId(message),
      title: payload['title'].toString(),
      body: payload['body'].toString(),
      payload: payload,
    );
  }

  static void handlePayload(Map<String, dynamic> payload) {
    pendingPayload = Map<String, dynamic>.from(payload);

    final listener = onPayloadReceived;
    if (listener != null) {
      listener(pendingPayload!);
    }
  }

  static Map<String, dynamic> consumePendingPayload() {
    final payload = pendingPayload;
    pendingPayload = null;

    return payload == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(payload);
  }

  static Future<void> registerDeviceToken(AppSession session) async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _saveToken(session, token, preserveCreatedAt: true);

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (newToken) async {
        if (newToken.isEmpty) return;
        await _saveToken(session, newToken, preserveCreatedAt: false);
      },
    );
  }

  static Future<void> deactivateCurrentToken(AppSession session) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    final tokenId = _tokenId(token);
    final now = DateTime.now().millisecondsSinceEpoch;

    await _firestore
        .doc(FirestorePaths.fcmToken(session.companyId, session.uid, tokenId))
        .set({
      'active': false,
      'updated_at': now,
      'last_seen_at': now,
    }, SetOptions(merge: true));
  }

  static Future<void> _saveToken(
    AppSession session,
    String token, {
    required bool preserveCreatedAt,
  }) async {
    final tokenId = _tokenId(token);
    final now = DateTime.now().millisecondsSinceEpoch;

    final ref = _firestore.doc(
      FirestorePaths.fcmToken(session.companyId, session.uid, tokenId),
    );

    final payload = <String, dynamic>{
      'token': token,
      'platform': Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : Platform.operatingSystem,
      'device_name': Platform.operatingSystem,
      'active': true,
      'updated_at': now,
      'last_seen_at': now,
      'uid': session.uid,
      'company_id': session.companyId,
    };

    if (!preserveCreatedAt) {
      payload['created_at'] = now;
    }

    await ref.set(payload, SetOptions(merge: true));

    if (preserveCreatedAt) {
      final snap = await ref.get();
      final data = snap.data();

      if (data == null || data['created_at'] == null) {
        await ref.set({'created_at': now}, SetOptions(merge: true));
      }
    }
  }

  static int _notificationId(RemoteMessage message) {
    final rawId = message.messageId;

    if (rawId != null && rawId.trim().isNotEmpty) {
      return rawId.hashCode.abs().remainder(2147483647);
    }

    return DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
  }

  static String _tokenId(String token) {
    return token.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  static Map<String, dynamic> _normalizePayload(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    final notification = message.notification;

    final title =
        notification?.title ?? data['title'] ?? data['notification_title'];

    final body = notification?.body ??
        data['body'] ??
        data['message'] ??
        data['notification_body'];

    data['title'] = (title?.toString().trim().isNotEmpty == true)
        ? title.toString()
        : 'MYPRESENSI';

    data['body'] = (body?.toString().trim().isNotEmpty == true)
        ? body.toString()
        : 'Ada notifikasi baru.';

    data['message'] = data['message']?.toString().trim().isNotEmpty == true
        ? data['message'].toString()
        : data['body'];

    if (message.messageId != null && message.messageId!.isNotEmpty) {
      data['message_id'] = message.messageId;
    }

    return data;
  }
}