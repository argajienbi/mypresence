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
        .collection(
            FirestorePaths.notificationInbox(session.companyId, session.uid))
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

  Future<void> markAsRead(
      AppSession session, AppNotification notification) async {
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

    await _database
        .ref('notifications/${session.uid}/${notification.id}')
        .update({
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

  Future<void> markAllPersonalAsRead(
    AppSession session,
    List<AppNotification> notifications,
  ) async {
    final unread = notifications
        .where((item) => !item.read && isPersonalNotification(item))
        .toList();

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

  List<AppNotification> mergePersonalInbox(
    List<AppNotification> firestore,
    List<AppNotification> rtdb,
  ) {
    return mergeInbox(firestore, rtdb).where(isPersonalNotification).toList();
  }

  int unreadPersonalCount(List<AppNotification> notifications) {
    return notifications
        .where((item) => !item.read && isPersonalNotification(item))
        .length;
  }

  bool isAnnouncementNotification(AppNotification item) {
    final value = _notificationSearchText(item);

    return value.contains('announcement') ||
        value.contains('pengumuman') ||
        value.contains('news') ||
        value.contains('company_event') ||
        value.contains('company event') ||
        value.contains('policy') ||
        value.contains('kebijakan') ||
        value.contains('info_umum') ||
        value.contains('info umum');
  }

  bool isPersonalNotification(AppNotification item) {
    final value = _notificationSearchText(item);

    if (isAnnouncementNotification(item)) return false;

    return value.contains('approval') ||
        value.contains('approved') ||
        value.contains('rejected') ||
        value.contains('disetujui') ||
        value.contains('ditolak') ||
        value.contains('pending') ||
        value.contains('leave') ||
        value.contains('izin') ||
        value.contains('sakit') ||
        value.contains('cuti') ||
        value.contains('lembur') ||
        value.contains('overtime') ||
        value.contains('correction') ||
        value.contains('koreksi') ||
        value.contains('schedule') ||
        value.contains('jadwal') ||
        value.contains('shift') ||
        value.contains('work_time') ||
        value.contains('work time') ||
        value.contains('jam kerja') ||
        value.contains('attendance') ||
        value.contains('presensi') ||
        value.contains('absensi') ||
        value.contains('attendance_reminder') ||
        value.contains('reminder') ||
        value.contains('pengingat') ||
        value.contains('qr') ||
        value.contains('status_update') ||
        value.contains('status update') ||
        value.contains('account_status') ||
        value.contains('status akun') ||
        value.contains('status_akun') ||
        value.contains('user_status') ||
        value.contains('user status') ||
        value.contains('validation') ||
        value.contains('warning') ||
        value.contains('alert') ||
        value.contains('system') ||
        value.contains('sistem');
  }

  String _notificationSearchText(AppNotification item) {
    return [
      item.type,
      item.refType,
      item.title,
      item.body,
      item.message,
      item.displayType,
      item.senderRole,
    ].join(' ').toLowerCase();
  }

  String _firstNonEmpty(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }
}
