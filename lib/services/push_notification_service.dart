import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/firestore_paths.dart';
import '../core/models/app_session.dart';
import 'attendance_reminder_service.dart';
import 'local_notification_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static const Duration _tokenRefreshDebounce = Duration(seconds: 45);

  static Map<String, dynamic>? pendingPayload;
  static void Function(Map<String, dynamic> payload)? onPayloadReceived;

  static bool _initialized = false;
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static StreamSubscription<RemoteMessage>? _openedSubscription;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static void Function(Map<String, dynamic> payload)? _notificationTapHandler;
  static final Map<String, Future<void>> _refreshInFlight = {};
  static final Map<String, DateTime> _lastRefreshCompletedAt = {};

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

    final settings = await _messaging.getNotificationSettings();
    final permissionStatus = settings.authorizationStatus.name;
    final statusbarAllowed = _statusbarAllowed(settings.authorizationStatus);
    final checkedAt = DateTime.now().millisecondsSinceEpoch;

    final token = await _messaging.getToken().timeout(
      const Duration(seconds: 12),
      onTimeout: () => null,
    );

    if (token == null || token.isEmpty) {
      await _writeTokenDebug(
        session,
        status: 'empty_token',
        permissionStatus: permissionStatus,
        statusbarAllowed: statusbarAllowed,
        lastError: 'token_unavailable',
      );
      return;
    }

    await _saveToken(
      session,
      token,
      permissionStatus: permissionStatus,
      statusbarAllowed: statusbarAllowed,
      permissionLastCheckedAt: checkedAt,
      preserveCreatedAt: true,
      debugStatus: statusbarAllowed
          ? 'registered'
          : permissionStatus == AuthorizationStatus.denied.name
              ? 'permission_denied'
              : 'registered',
      invalidateSupersededTokens: statusbarAllowed,
    );

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (newToken) async {
        try {
          final latestSettings = await _messaging.getNotificationSettings();
          final latestPermissionStatus = latestSettings.authorizationStatus.name;
          final latestStatusbarAllowed =
              _statusbarAllowed(latestSettings.authorizationStatus);
          final latestCheckedAt = DateTime.now().millisecondsSinceEpoch;

          if (newToken.isEmpty) {
            await _writeTokenDebug(
              session,
              status: 'empty_token',
              permissionStatus: latestPermissionStatus,
              statusbarAllowed: latestStatusbarAllowed,
              lastError: 'token_unavailable',
            );
            return;
          }

          await _saveToken(
            session,
            newToken,
            permissionStatus: latestPermissionStatus,
            statusbarAllowed: latestStatusbarAllowed,
            permissionLastCheckedAt: latestCheckedAt,
            preserveCreatedAt: true,
            debugStatus: latestStatusbarAllowed
                ? 'refreshed'
                : latestSettings.authorizationStatus == AuthorizationStatus.denied
                    ? 'permission_denied'
                    : 'refreshed',
            invalidateSupersededTokens: latestStatusbarAllowed,
          );
        } catch (e) {
          await _writeTokenDebug(
            session,
            status: 'error',
            permissionStatus: '',
            statusbarAllowed: false,
            lastError: e.toString(),
          );
        }
      },
    );
  }

  static Future<void> refreshCurrentTokenStatus(
    AppSession session, {
    bool force = false,
  }) {
    final key = _sessionKey(session);
    final inFlight = _refreshInFlight[key];
    if (inFlight != null) return inFlight;

    final lastCompleted = _lastRefreshCompletedAt[key];
    if (!force &&
        lastCompleted != null &&
        DateTime.now().difference(lastCompleted) < _tokenRefreshDebounce) {
      return Future<void>.value();
    }

    final future = _refreshCurrentTokenStatusInternal(session).whenComplete(() {
      _refreshInFlight.remove(key);
      _lastRefreshCompletedAt[key] = DateTime.now();
    });
    _refreshInFlight[key] = future;
    return future;
  }

  static Future<void> _refreshCurrentTokenStatusInternal(
    AppSession session,
  ) async {
    try {
      final latestSettings = await _messaging.getNotificationSettings();
      final latestPermissionStatus = latestSettings.authorizationStatus.name;
      final latestStatusbarAllowed =
          _statusbarAllowed(latestSettings.authorizationStatus);
      final latestCheckedAt = DateTime.now().millisecondsSinceEpoch;
      final token = await _messaging.getToken().timeout(
        const Duration(seconds: 12),
        onTimeout: () => null,
      );

      if (token == null || token.isEmpty) {
        await _writeTokenDebug(
          session,
          status: 'empty_token',
          permissionStatus: latestPermissionStatus,
          statusbarAllowed: latestStatusbarAllowed,
          lastError: 'token_unavailable',
        );
        return;
      }

      await _saveToken(
        session,
        token,
        permissionStatus: latestPermissionStatus,
        statusbarAllowed: latestStatusbarAllowed,
        permissionLastCheckedAt: latestCheckedAt,
        preserveCreatedAt: true,
        debugStatus: latestStatusbarAllowed
            ? 'refreshed'
            : latestSettings.authorizationStatus == AuthorizationStatus.denied
                ? 'permission_denied'
                : 'refreshed',
        invalidateSupersededTokens: latestStatusbarAllowed,
      );
    } catch (e) {
      await _writeTokenDebug(
        session,
        status: 'error',
        permissionStatus: '',
        statusbarAllowed: false,
        lastError: e.toString(),
      );
    }
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
    required bool statusbarAllowed,
    required int permissionLastCheckedAt,
    required bool preserveCreatedAt,
    String debugStatus = 'registered',
    bool invalidateSupersededTokens = false,
  }) async {
    final tokenId = _tokenId(token);
    final now = DateTime.now().millisecondsSinceEpoch;

    final ref = _firestore.doc(
      FirestorePaths.fcmToken(session.companyId, session.uid, tokenId),
    );
    final existingSnap = await ref.get();
    final existingData = existingSnap.data();
    final existingInvalidReason =
        (existingData?['invalid_reason']?.toString().trim() ?? '');
    final shouldClearInvalidReason =
        existingInvalidReason == 'notification_permission_denied' &&
            permissionStatus != AuthorizationStatus.denied.name;
    final createdAt = preserveCreatedAt
        ? _asInt(existingData?['created_at'], now)
        : now;
    final active = token.isNotEmpty && statusbarAllowed;

    final basePayload = <String, dynamic>{
      'token': token,
      'token_id': tokenId,
      'platform': Platform.isAndroid
          ? 'android'
          : Platform.isIOS
              ? 'ios'
              : Platform.operatingSystem,
      'device_name': Platform.operatingSystem,
      'permission_status': permissionStatus,
      'statusbar_allowed': statusbarAllowed,
      'active': active,
      'updated_at': now,
      'last_seen_at': now,
      'permission_last_checked_at': permissionLastCheckedAt,
      'uid': session.uid,
      'company_id': session.companyId,
      'app_source': 'mypresence',
      'created_at': createdAt,
    };

    final firestorePayload = <String, dynamic>{
      ...basePayload,
    };
    final rtdbPayload = <String, dynamic>{
      ...basePayload,
    };

    if (statusbarAllowed) {
      if (shouldClearInvalidReason) {
        firestorePayload['invalid_reason'] = FieldValue.delete();
        rtdbPayload['invalid_reason'] = null;
      }
    } else if (permissionStatus == AuthorizationStatus.denied.name) {
      firestorePayload['invalid_reason'] = 'notification_permission_denied';
      rtdbPayload['invalid_reason'] = 'notification_permission_denied';
    }

    await ref.set(firestorePayload, SetOptions(merge: true));
    if (shouldClearInvalidReason) {
      await ref
          .set({'invalid_reason': FieldValue.delete()}, SetOptions(merge: true))
          .catchError((_) {});
    }

    // Mirror ringan ke RTDB untuk debugging mobile/admin.
    final rtdbRef =
        _database.ref('companies/${session.companyId}/users/${session.uid}/fcm_tokens/$tokenId');
    await _database
        .ref('companies/${session.companyId}/users/${session.uid}/fcm_tokens/$tokenId')
        .set(rtdbPayload)
        .catchError((_) {});
    if (shouldClearInvalidReason) {
      await rtdbRef.update({'invalid_reason': null}).catchError((_) {});
    }

    if (invalidateSupersededTokens && active) {
      await _deactivateSupersededTokens(
        session,
        currentTokenId: tokenId,
        platform: basePayload['platform'].toString(),
        now: now,
      );
    }

    await _writeTokenDebug(
      session,
      status: debugStatus,
      permissionStatus: permissionStatus,
      statusbarAllowed: statusbarAllowed,
      tokenId: tokenId,
    );
  }

  static Future<void> _writeTokenDebug(
    AppSession session, {
    required String status,
    required String permissionStatus,
    required bool statusbarAllowed,
    String tokenId = '',
    String lastError = '',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _database
        .ref('companies/${session.companyId}/users/${session.uid}/fcm_token_status')
        .set({
      'status': status,
      'permission_status': permissionStatus,
      'statusbar_allowed': statusbarAllowed,
      'token_id': tokenId,
      'updated_at': now,
      'platform': Platform.operatingSystem,
      'last_error': lastError,
    }).catchError((_) {});
  }

  static Future<void> openNotificationSettings() async {
    await openAppSettings();
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

  static bool _statusbarAllowed(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  static String _sessionKey(AppSession session) {
    return '${session.companyId}:${session.uid}';
  }

  static Future<void> _deactivateSupersededTokens(
    AppSession session, {
    required String currentTokenId,
    required String platform,
    required int now,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.fcmTokens(session.companyId, session.uid))
          .get();

      for (final doc in snapshot.docs) {
        if (doc.id == currentTokenId) continue;

        final data = doc.data();
        final docPlatform = data['platform']?.toString().trim() ?? '';
        final appSource = data['app_source']?.toString().trim() ?? '';
        final docUid = data['uid']?.toString().trim() ?? '';
        final docCompanyId = data['company_id']?.toString().trim() ?? '';
        if (docPlatform != platform ||
            appSource != 'mypresence' ||
            docUid != session.uid ||
            docCompanyId != session.companyId) {
          continue;
        }

        final inactivePayload = <String, dynamic>{
          'active': false,
          'updated_at': now,
          'invalidated_at': now,
          'invalid_reason': 'superseded_by_new_token',
          'superseded_by': currentTokenId,
        };

        await doc.reference
            .set(inactivePayload, SetOptions(merge: true))
            .catchError((_) {});
        await _database
            .ref(
              'companies/${session.companyId}/users/${session.uid}/fcm_tokens/${doc.id}',
            )
            .update(inactivePayload)
            .catchError((_) {});
      }
    } catch (_) {}
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

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return int.tryParse(value.toString()) ?? fallback;
  }
}
