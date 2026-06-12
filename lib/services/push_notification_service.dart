import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/firestore_paths.dart';
import '../core/models/app_session.dart';
import 'attendance_reminder_service.dart';
import 'local_notification_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  static Map<String, dynamic>? pendingPayload;
  static void Function(Map<String, dynamic> payload)? onPayloadReceived;

  static bool _initialized = false;
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static StreamSubscription<RemoteMessage>? _openedSubscription;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static void Function(Map<String, dynamic> payload)? _notificationTapHandler;

  static Future<void> initialize({
    required void Function(Map<String, dynamic> payload) onNotificationTap,
  }) async {
    _notificationTapHandler = onNotificationTap;

    if (_initialized) return;

    try {
      await _messaging.setAutoInitEnabled(true);

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
        onTap: _handleNotificationTap,
      );

      await _foregroundSubscription?.cancel();
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) async {
          await showForegroundMessage(message);
        },
      );

      await _openedSubscription?.cancel();
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (RemoteMessage message) {
          _handleNotificationTap(_normalizePayload(message));
        },
      );

      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _handleNotificationTap(_normalizePayload(initial));
      }

      _initialized = true;
    } catch (_) {
      _initialized = false;
      rethrow;
    }
  }

  static Future<void> showForegroundMessage(RemoteMessage message) async {
    await LocalNotificationService.initialize(onTap: _handleNotificationTap);

    final payload = _normalizePayload(message);
    await AttendanceReminderService.cancelScheduledReminderByNotificationId(
      payload['notification_id'].toString(),
    );

    await LocalNotificationService.show(
      id: _notificationId(message),
      title: payload['title'].toString(),
      body: payload['body'].toString(),
      payload: payload,
    );
  }

  static Future<void> showBackgroundMessage(RemoteMessage message) async {
    final payload = _normalizePayload(message);
    await AttendanceReminderService.cancelScheduledReminderByNotificationId(
      payload['notification_id'].toString(),
    );

    // Jika payload FCM berisi notification dan aplikasi background/killed,
    // Android biasanya menampilkan notification otomatis.
    // Local notification tetap hanya dipakai untuk data-only agar tidak dobel.
    if (message.notification != null) return;

    await LocalNotificationService.initialize(
      onTap: _handleNotificationTap,
    );

    await LocalNotificationService.show(
      id: _notificationId(message),
      title: payload['title'].toString(),
      body: payload['body'].toString(),
      payload: payload,
    );
  }

  static void _handleNotificationTap(Map<String, dynamic> payload) {
    final handler = _notificationTapHandler;
    if (handler != null) {
      handler(payload);
      return;
    }

    handlePayload(payload);
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
    await _messaging.setAutoInitEnabled(true);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final token = await _messaging.getToken().timeout(
      const Duration(seconds: 12),
      onTimeout: () => null,
    );

    if (token == null || token.isEmpty) {
      await _writeTokenDebug(
        session,
        status: 'empty_token',
        permissionStatus: settings.authorizationStatus.name,
      );
      return;
    }

    await _saveToken(
      session,
      token,
      permissionStatus: settings.authorizationStatus.name,
      preserveCreatedAt: true,
    );

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (newToken) async {
        if (newToken.isEmpty) return;
        await _saveToken(
          session,
          newToken,
          permissionStatus: settings.authorizationStatus.name,
          preserveCreatedAt: true,
        );
      },
    );
  }

  static Future<void> deactivateCurrentToken(AppSession session) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    final tokenId = _tokenId(token);
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = {
      'active': false,
      'updated_at': now,
      'last_seen_at': now,
    };

    await _firestore
        .doc(FirestorePaths.fcmToken(session.companyId, session.uid, tokenId))
        .set(payload, SetOptions(merge: true));

    await _database
        .ref('companies/${session.companyId}/users/${session.uid}/fcm_tokens/$tokenId')
        .update(payload)
        .catchError((_) {});
  }

  static Future<void> _saveToken(
    AppSession session,
    String token, {
    required String permissionStatus,
    required bool preserveCreatedAt,
  }) async {
    final tokenId = _tokenId(token);
    final now = DateTime.now().millisecondsSinceEpoch;

    final ref = _firestore.doc(
      FirestorePaths.fcmToken(session.companyId, session.uid, tokenId),
    );

    final payload = <String, dynamic>{
      'token': token,
      'token_id': tokenId,
      'platform': Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : Platform.operatingSystem,
      'device_name': Platform.operatingSystem,
      'permission_status': permissionStatus,
      'active': true,
      'updated_at': now,
      'last_seen_at': now,
      'uid': session.uid,
      'company_id': session.companyId,
      'app_source': 'mypresence',
    };

    if (!preserveCreatedAt) {
      payload['created_at'] = now;
    }

    await ref.set(payload, SetOptions(merge: true));

    final snap = await ref.get();
    final data = snap.data();
    if (data == null || data['created_at'] == null) {
      await ref.set({'created_at': now}, SetOptions(merge: true));
    }

    // Mirror ringan ke RTDB untuk debugging mobile/admin.
    await _database
        .ref('companies/${session.companyId}/users/${session.uid}/fcm_tokens/$tokenId')
        .set({
      ...payload,
      'created_at': data?['created_at'] ?? now,
    }).catchError((_) {});

    await _writeTokenDebug(
      session,
      status: 'registered',
      permissionStatus: permissionStatus,
      tokenId: tokenId,
    );
  }

  static Future<void> _writeTokenDebug(
    AppSession session, {
    required String status,
    required String permissionStatus,
    String tokenId = '',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _database
        .ref('companies/${session.companyId}/users/${session.uid}/fcm_token_status')
        .set({
      'status': status,
      'permission_status': permissionStatus,
      'token_id': tokenId,
      'updated_at': now,
      'platform': Platform.operatingSystem,
    }).catchError((_) {});
  }

  static int _notificationId(RemoteMessage message) {
    final rawId = message.messageId;

    if (rawId != null && rawId.trim().isNotEmpty) {
      return rawId.hashCode.abs().remainder(2147483647);
    }

    final dataId = message.data['notification_id'] ?? message.data['queue_id'];
    if (dataId != null && dataId.toString().trim().isNotEmpty) {
      return dataId.toString().hashCode.abs().remainder(2147483647);
    }

    return DateTime.now().millisecondsSinceEpoch.remainder(2147483647);
  }

  static String _tokenId(String token) {
    return token.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  static Map<String, dynamic> _normalizePayload(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    final notification = message.notification;

    final title = _firstNonEmptyText([
      notification?.title,
      data['title'],
      data['notification_title'],
    ], fallback: 'MYPRESENSI');

    final body = _firstNonEmptyText([
      notification?.body,
      data['body'],
      data['message'],
      data['notification_body'],
    ], fallback: 'Ada notifikasi baru.');

    data['title'] = title;
    data['body'] = body;

    data['message'] = data['message']?.toString().trim().isNotEmpty == true
        ? data['message'].toString()
        : data['body'];

    data['ref_type'] = _firstNonEmptyText([
      data['ref_type'],
      data['type'],
    ]);

    final notificationId = [
      data['notification_id'],
      data['id'],
      data['inbox_id'],
      message.messageId,
    ].map((value) => value?.toString().trim() ?? '').firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => '',
        );
    if (notificationId.isNotEmpty) {
      data['notification_id'] = notificationId;
      if ((data['id']?.toString().trim() ?? '').isEmpty) {
        data['id'] = notificationId;
      }
      if ((data['inbox_id']?.toString().trim() ?? '').isEmpty) {
        data['inbox_id'] = notificationId;
      }
    }

    if (message.messageId != null && message.messageId!.isNotEmpty) {
      data['message_id'] = message.messageId;
    }

    return data;
  }

  static String _firstNonEmptyText(
    List<dynamic> values, {
    String fallback = '',
  }) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }
}
