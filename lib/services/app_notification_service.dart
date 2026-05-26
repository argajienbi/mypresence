import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../core/firestore_paths.dart';
import '../core/models/app_notification.dart';
import '../core/models/app_session.dart';

class AppNotificationService {
  AppNotificationService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Stream<List<AppNotification>> watchFirestoreInbox(AppSession session) {
    return _firestore
        .collection(FirestorePaths.notificationInbox(session.companyId, session.uid))
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => AppNotification.fromMap(
                  doc.id,
                  doc.data(),
                  fallbackCompanyId: session.companyId,
                  fallbackUid: session.uid,
                ),
              )
              .toList(),
        );
  }

  Stream<List<AppNotification>> watchRtdbFallback(AppSession session) {
    return _database.ref('notifications/${session.uid}').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return <AppNotification>[];

      final items = <AppNotification>[];
      for (final entry in value.entries) {
        final rawValue = entry.value;
        if (rawValue is! Map) continue;
        final id = entry.key.toString();
        final raw = Map<String, dynamic>.from(rawValue);
        items.add(
          AppNotification.fromMap(
            id,
            raw,
            fallbackCompanyId: session.companyId,
            fallbackUid: session.uid,
          ),
        );
      }

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<void> markAsRead(AppSession session, AppNotification notification) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _firestore
        .doc(FirestorePaths.notificationItem(
          session.companyId,
          session.uid,
          notification.id,
        ))
        .set({
      'read': true,
      'is_read': true,
      'read_at': now,
    }, SetOptions(merge: true)).catchError((_) {});

    await _database.ref('notifications/${session.uid}/${notification.id}').update({
      'read': true,
      'is_read': true,
      'read_at': now,
    }).catchError((_) {});
  }

  Future<void> markPayloadAsRead(
    AppSession session,
    Map<String, dynamic> payload,
  ) async {
    final notificationId = _firstNonEmpty(payload, const [
      'notification_id',
      'id',
      'inbox_id',
    ]);
    if (notificationId.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    await _firestore
        .doc(FirestorePaths.notificationItem(
          session.companyId,
          session.uid,
          notificationId,
        ))
        .set({
      'read': true,
      'is_read': true,
      'read_at': now,
    }, SetOptions(merge: true)).catchError((_) {});

    await _database.ref('notifications/${session.uid}/$notificationId').update({
      'read': true,
      'is_read': true,
      'read_at': now,
    }).catchError((_) {});
  }

  Future<void> markAllAsRead(
    AppSession session,
    List<AppNotification> notifications,
  ) async {
    final unread = notifications.where((e) => !e.read).toList();
    for (final item in unread) {
      await markAsRead(session, item);
    }
  }

  List<AppNotification> mergeInbox(
    List<AppNotification> firestore,
    List<AppNotification> rtdb,
  ) {
    final map = <String, AppNotification>{};

    for (final item in rtdb) {
      map[item.dedupeKey] = item;
    }

    // Prefer Firestore inbox when both RTDB fallback and Firestore contain the same ref/id.
    for (final item in firestore) {
      map[item.dedupeKey] = item;
    }

    final list = map.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  String _firstNonEmpty(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }
}
