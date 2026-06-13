import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../core/firestore_paths.dart';
import '../core/models/app_session.dart';

class NotificationService {
  NotificationService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<Map<String, dynamic>> createNotification({
    required AppSession session,
    required String title,
    required String body,
    required String type,
    String companyId = '',
    String relatedId = '',
    String refType = '',
    String refId = '',
    String notificationId = '',
    String senderUid = 'system',
    String senderName = 'Sistem',
    String senderRole = 'system',
    bool read = false,
    bool active = true,
    int? createdAt,
    Map<String, dynamic> extra = const {},
  }) async {
    final now = createdAt ?? DateTime.now().millisecondsSinceEpoch;
    final resolvedCompanyId =
        companyId.trim().isNotEmpty ? companyId.trim() : session.companyId;
    final resolvedNotificationId = notificationId.trim().isNotEmpty
        ? notificationId.trim()
        : _generateNotificationId(
            session: session,
            type: type,
            refType: refType,
            refId: refId.isNotEmpty ? refId : relatedId,
            createdAt: now,
          );

    final payload = <String, dynamic>{
      ...extra,
      'notification_id': resolvedNotificationId,
      'id': resolvedNotificationId,
      'inbox_id': resolvedNotificationId,
      'company_id': resolvedCompanyId,
      'uid': session.uid,
      'title': _cleanText(title, fallback: 'MYPRESENSI'),
      'body': _cleanText(body, fallback: 'Ada notifikasi baru.'),
      'message': _cleanText(body, fallback: _cleanText(title, fallback: 'Ada notifikasi baru.')),
      'type': _cleanText(type, fallback: 'info'),
      'ref_type': _cleanText(refType),
      'ref_id': _cleanText(refId, fallback: _cleanText(relatedId)),
      'related_id': _cleanText(relatedId, fallback: _cleanText(refId)),
      'sender_uid': _cleanText(senderUid, fallback: 'system'),
      'sender_name': _cleanText(senderName, fallback: 'Sistem'),
      'sender_role': _cleanText(senderRole, fallback: 'system'),
      'created_at': now,
      'created_date': _dateKey(now),
      'created_time': _timeKey(now),
      'read': read,
      'is_read': read,
      'active': active,
      'updated_at': now,
    };

    return upsertPayload(
      session: session,
      payload: payload,
      preserveReadState: true,
    );
  }

  Future<Map<String, dynamic>> upsertPayload({
    required AppSession session,
    required Map<String, dynamic> payload,
    bool preserveReadState = true,
    bool preserveActiveState = true,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final normalized = _normalizePayload(session, payload, now: now);
    final notificationId = normalized['notification_id'].toString().trim();
    final companyId = normalized['company_id'].toString().trim();
    final uid = normalized['uid'].toString().trim();

    final firestorePath = FirestorePaths.notificationItem(
      companyId,
      uid,
      notificationId,
    );
    final rtdbPath = 'notifications/$uid/$notificationId';

    Map<String, dynamic> firestoreData = <String, dynamic>{};
    try {
      final firestoreSnap = await _firestore.doc(firestorePath).get();
      firestoreData = firestoreSnap.data() ?? <String, dynamic>{};
    } catch (_) {}

    Map<String, dynamic> rtdbData = <String, dynamic>{};
    try {
      final rtdbSnap = await _database.ref(rtdbPath).get();
      rtdbData = _snapshotMap(rtdbSnap.value);
    } catch (_) {}

    final merged = <String, dynamic>{
      ...rtdbData,
      ...firestoreData,
      ...normalized,
    };

    merged['notification_id'] = notificationId;
    merged['id'] = notificationId;
    merged['inbox_id'] = notificationId;
    merged['company_id'] = companyId;
    merged['uid'] = uid;
    merged['title'] = _cleanText(merged['title'], fallback: 'MYPRESENSI');
    merged['body'] = _cleanText(merged['body'], fallback: 'Ada notifikasi baru.');
    merged['message'] = _cleanText(
      merged['message'],
      fallback: merged['body'].toString(),
    );
    merged['type'] = _cleanText(merged['type'], fallback: 'info');
    merged['ref_type'] = _cleanText(merged['ref_type']);
    merged['ref_id'] = _cleanText(
      merged['ref_id'],
      fallback: _cleanText(merged['related_id']),
    );
    merged['related_id'] = _cleanText(
      merged['related_id'],
      fallback: _cleanText(merged['ref_id']),
    );
    merged['sender_uid'] = _cleanText(merged['sender_uid'], fallback: 'system');
    merged['sender_name'] = _cleanText(merged['sender_name'], fallback: 'Sistem');
    merged['sender_role'] = _cleanText(merged['sender_role'], fallback: 'system');
    merged['created_at'] = _asInt(merged['created_at'], now);
    merged['created_date'] = _cleanText(
      merged['created_date'],
      fallback: _dateKey(_asInt(merged['created_at'], now)),
    );
    merged['created_time'] = _cleanText(
      merged['created_time'],
      fallback: _timeKey(_asInt(merged['created_at'], now)),
    );
    merged['updated_at'] = now;

    if (preserveReadState) {
      final read = _asBool(firestoreData['read']) ||
          _asBool(firestoreData['is_read']) ||
          _asBool(rtdbData['read']) ||
          _asBool(rtdbData['is_read']) ||
          _asBool(merged['read']) ||
          _asBool(merged['is_read']);
      merged['read'] = read;
      merged['is_read'] = read;

      final readAt = _firstNonEmpty([
        firestoreData['read_at'],
        firestoreData['readAt'],
        rtdbData['read_at'],
        rtdbData['readAt'],
        merged['read_at'],
        merged['readAt'],
      ]);
      if (readAt.isNotEmpty) {
        merged['read_at'] = _asInt(readAt, now);
      }
    }

    final existingActive = _firstBool([
      firestoreData['active'],
      rtdbData['active'],
    ]);
    if (preserveActiveState && existingActive != null) {
      merged['active'] = existingActive;
    } else {
      merged['active'] = _asBool(merged['active'], true);
    }

    await _firestore
        .doc(firestorePath)
        .set(merged, SetOptions(merge: true))
        .catchError((_) {});
    await _database.ref(rtdbPath).set(merged).catchError((_) {});

    return merged;
  }

  Future<Map<String, dynamic>> updateNotificationFields({
    required AppSession session,
    required String notificationId,
    required Map<String, dynamic> fields,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final notificationKey = notificationId.trim();
    final firestorePath = FirestorePaths.notificationItem(
      session.companyId,
      session.uid,
      notificationKey,
    );
    final rtdbPath = 'notifications/${session.uid}/$notificationKey';

    Map<String, dynamic> firestoreData = <String, dynamic>{};
    try {
      final firestoreSnap = await _firestore.doc(firestorePath).get();
      firestoreData = firestoreSnap.data() ?? <String, dynamic>{};
    } catch (_) {}

    Map<String, dynamic> rtdbData = <String, dynamic>{};
    try {
      final rtdbSnap = await _database.ref(rtdbPath).get();
      rtdbData = _snapshotMap(rtdbSnap.value);
    } catch (_) {}

    final merged = <String, dynamic>{
      ...rtdbData,
      ...firestoreData,
      ...fields,
      'notification_id': notificationKey,
      'id': notificationKey,
      'inbox_id': notificationKey,
      'company_id': _cleanText(
        fields['company_id'],
        fallback: _cleanText(firestoreData['company_id'],
            fallback: _cleanText(rtdbData['company_id'], fallback: session.companyId)),
      ),
      'uid': _cleanText(
        fields['uid'],
        fallback: _cleanText(firestoreData['uid'],
            fallback: _cleanText(rtdbData['uid'], fallback: session.uid)),
      ),
      'updated_at': now,
    };

    merged['title'] = _cleanText(merged['title'], fallback: 'MYPRESENSI');
    merged['body'] = _cleanText(merged['body'], fallback: 'Ada notifikasi baru.');
    merged['message'] = _cleanText(
      merged['message'],
      fallback: merged['body'].toString(),
    );
    merged['type'] = _cleanText(merged['type'], fallback: 'info');
    merged['ref_type'] = _cleanText(merged['ref_type']);
    merged['ref_id'] = _cleanText(
      merged['ref_id'],
      fallback: _cleanText(merged['related_id']),
    );
    merged['related_id'] = _cleanText(
      merged['related_id'],
      fallback: _cleanText(merged['ref_id']),
    );
    merged['sender_uid'] = _cleanText(merged['sender_uid'], fallback: 'system');
    merged['sender_name'] = _cleanText(merged['sender_name'], fallback: 'Sistem');
    merged['sender_role'] = _cleanText(merged['sender_role'], fallback: 'system');
    merged['created_at'] = _asInt(merged['created_at'], now);
    merged['created_date'] = _cleanText(
      merged['created_date'],
      fallback: _dateKey(_asInt(merged['created_at'], now)),
    );
    merged['created_time'] = _cleanText(
      merged['created_time'],
      fallback: _timeKey(_asInt(merged['created_at'], now)),
    );

    final shouldPreserveRead = !fields.containsKey('read') &&
        !fields.containsKey('is_read');
    if (shouldPreserveRead) {
      final read = _asBool(firestoreData['read']) ||
          _asBool(firestoreData['is_read']) ||
          _asBool(rtdbData['read']) ||
          _asBool(rtdbData['is_read']) ||
          _asBool(merged['read']) ||
          _asBool(merged['is_read']);
      merged['read'] = read;
      merged['is_read'] = read;

      final readAt = _firstNonEmpty([
        firestoreData['read_at'],
        firestoreData['readAt'],
        rtdbData['read_at'],
        rtdbData['readAt'],
        merged['read_at'],
        merged['readAt'],
      ]);
      if (readAt.isNotEmpty) {
        merged['read_at'] = _asInt(readAt, now);
      }
    } else {
      merged['read'] = _asBool(fields['read'], _asBool(fields['is_read']));
      merged['is_read'] = _asBool(fields['is_read'], _asBool(fields['read']));
      final readAt = _firstNonEmpty([
        fields['read_at'],
        fields['readAt'],
      ]);
      if (readAt.isNotEmpty) {
        merged['read_at'] = _asInt(readAt, now);
      }
    }

    if (fields.containsKey('active')) {
      merged['active'] = _asBool(fields['active'], true);
    } else {
      final existingActive = _firstBool([
        firestoreData['active'],
        rtdbData['active'],
      ]);
      merged['active'] = existingActive ?? true;
    }

    await _firestore
        .doc(firestorePath)
        .set(merged, SetOptions(merge: true))
        .catchError((_) {});
    await _database.ref(rtdbPath).set(merged).catchError((_) {});

    return merged;
  }

  Future<List<Map<String, dynamic>>> listUserNotifications(String uid) async {
    final snap = await _database.ref('notifications/$uid').get();
    final value = snap.value;
    if (value is! Map) return <Map<String, dynamic>>[];

    final items = <Map<String, dynamic>>[];
    for (final entry in value.entries) {
      final raw = _snapshotMap(entry.value);
      raw['id'] = entry.key.toString();
      items.add(raw);
    }

    items.sort(
      (a, b) => _asInt(b['created_at']).compareTo(_asInt(a['created_at'])),
    );
    return items;
  }

  String _generateNotificationId({
    required AppSession session,
    required String type,
    required String refType,
    required String refId,
    required int createdAt,
  }) {
    final seed = [
      session.companyId,
      session.uid,
      type,
      refType,
      refId,
      createdAt.toString(),
    ].where((part) => part.trim().isNotEmpty).join('|');
    final slug = seed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return 'notif_${createdAt}_$slug';
  }

  Map<String, dynamic> _normalizePayload(
    AppSession session,
    Map<String, dynamic> payload, {
    required int now,
  }) {
    final map = <String, dynamic>{...payload};

    final notificationId = _cleanText(
      map['notification_id'],
      fallback: _cleanText(map['id'], fallback: _cleanText(map['inbox_id'])),
    );
    final refId = _cleanText(
      map['ref_id'],
      fallback: _cleanText(map['related_id']),
    );
    final relatedId = _cleanText(
      map['related_id'],
      fallback: _cleanText(map['ref_id']),
    );
    final createdAt = _asInt(map['created_at'], now);

    map['notification_id'] = notificationId.isNotEmpty
        ? notificationId
        : _generateNotificationId(
            session: session,
            type: map['type']?.toString() ?? 'info',
            refType: map['ref_type']?.toString() ?? '',
            refId: refId.isNotEmpty ? refId : relatedId,
            createdAt: createdAt,
          );
    map['id'] = map['notification_id'];
    map['inbox_id'] = map['notification_id'];
    map['company_id'] = _cleanText(map['company_id'], fallback: session.companyId);
    map['uid'] = _cleanText(map['uid'], fallback: session.uid);
    map['title'] = _cleanText(map['title'], fallback: 'MYPRESENSI');
    map['body'] = _cleanText(
      map['body'],
      fallback: _cleanText(map['message'], fallback: 'Ada notifikasi baru.'),
    );
    map['message'] = _cleanText(
      map['message'],
      fallback: _cleanText(map['body'], fallback: 'Ada notifikasi baru.'),
    );
    map['type'] = _cleanText(map['type'], fallback: 'info');
    map['ref_type'] = _cleanText(map['ref_type']);
    map['ref_id'] = refId.isNotEmpty ? refId : relatedId;
    map['related_id'] = relatedId.isNotEmpty ? relatedId : refId;
    map['sender_uid'] = _cleanText(map['sender_uid'], fallback: 'system');
    map['sender_name'] = _cleanText(map['sender_name'], fallback: 'Sistem');
    map['sender_role'] = _cleanText(map['sender_role'], fallback: 'system');
    map['created_at'] = createdAt;
    map['created_date'] = _cleanText(
      map['created_date'],
      fallback: _dateKey(createdAt),
    );
    map['created_time'] = _cleanText(
      map['created_time'],
      fallback: _timeKey(createdAt),
    );
    map['updated_at'] = _asInt(map['updated_at'], now);
    map['read'] = _asBool(map['read']);
    map['is_read'] = _asBool(map['is_read'], _asBool(map['read']));
    map['active'] = map.containsKey('active') ? _asBool(map['active'], true) : true;

    return map;
  }

  Map<String, dynamic> _snapshotMap(dynamic value) {
    if (value is! Map) return <String, dynamic>{};
    return value.map((key, val) => MapEntry(key.toString(), val));
  }

  String _cleanText(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isNotEmpty ? text : fallback;
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  bool? _firstBool(List<dynamic> values) {
    for (final value in values) {
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
    return null;
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return int.tryParse(value.toString()) ?? fallback;
  }

  bool _asBool(dynamic value, [bool fallback = false]) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return fallback;
    return text == 'true' || text == '1' || text == 'yes' || text == 'y';
  }

  String _dateKey(int timestamp) {
    if (timestamp <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return [
      date.year.toString().padLeft(4, '0'),
      date.month.toString().padLeft(2, '0'),
      date.day.toString().padLeft(2, '0'),
    ].join('-');
  }

  String _timeKey(int timestamp) {
    if (timestamp <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return [
      date.hour.toString().padLeft(2, '0'),
      date.minute.toString().padLeft(2, '0'),
    ].join(':');
  }
}
