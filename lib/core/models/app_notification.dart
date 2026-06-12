import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String companyId;
  final String uid;
  final String title;
  final String body;
  final String message;
  final String type;
  final String refType;
  final String refId;
  final String relatedId;
  final String senderUid;
  final String senderName;
  final String senderRole;
  final String createdDate;
  final String createdTime;
  final bool read;
  final int createdAt;
  final Map<String, dynamic> raw;

  const AppNotification({
    required this.id,
    required this.companyId,
    required this.uid,
    required this.title,
    required this.body,
    required this.message,
    required this.type,
    required this.refType,
    required this.refId,
    required this.relatedId,
    required this.senderUid,
    required this.senderName,
    required this.senderRole,
    required this.createdDate,
    required this.createdTime,
    required this.read,
    required this.createdAt,
    required this.raw,
  });

  factory AppNotification.fromMap(
    String id,
    Map<String, dynamic> data, {
    String fallbackCompanyId = '',
    String fallbackUid = '',
  }) {
    final map = Map<String, dynamic>.from(data);
    final createdAt = _asInt(
      map['created_at'],
      _asInt(map['timestamp']),
    );

    final body = _firstNonEmpty([
      map['body'],
      map['message'],
      map['notification_body'],
      map['text'],
    ]);

    final message = _firstNonEmpty([
      map['message'],
      map['body'],
      map['notification_body'],
      body,
    ]);

    final createdDate = _firstNonEmpty([
      map['created_date'],
      map['date'],
      map['tanggal'],
      _dateFromTimestamp(createdAt),
    ]);

    final createdTime = _firstNonEmpty([
      map['created_time'],
      map['time'],
      map['waktu'],
      _timeFromTimestamp(createdAt),
    ]);

    final notificationId = _firstNonEmpty([
      map['id'],
      map['notification_id'],
      id,
    ]);

    final refId = _firstNonEmpty([
      map['ref_id'],
      map['related_id'],
      map['refId'],
      map['relatedId'],
    ]);

    final relatedId = _firstNonEmpty([
      map['related_id'],
      map['ref_id'],
      map['relatedId'],
      map['refId'],
    ]);

    return AppNotification(
      id: notificationId,
      companyId: _firstNonEmpty([map['company_id'], fallbackCompanyId]),
      uid: _firstNonEmpty([map['uid'], fallbackUid]),
      title: _firstNonEmpty([map['title']], fallback: 'MYPRESENSI'),
      body: body,
      message: message,
      type: _firstNonEmpty([map['type']], fallback: 'info'),
      refType: _firstNonEmpty([
        map['ref_type'],
        map['refType'],
        map['type'],
      ]),
      refId: refId,
      relatedId: relatedId,
      senderUid: _firstNonEmpty([map['sender_uid'], map['senderUid']]),
      senderName: _firstNonEmpty([map['sender_name'], map['senderName']],
          fallback: 'Sistem'),
      senderRole: _firstNonEmpty([map['sender_role'], map['senderRole']],
          fallback: 'system'),
      createdDate: createdDate,
      createdTime: createdTime,
      read: _asBool(map['read']) || _asBool(map['is_read']),
      createdAt: createdAt,
      raw: map,
    );
  }

  String get displayBody {
    if (body.trim().isNotEmpty) return body;
    if (message.trim().isNotEmpty) return message;
    return title;
  }

  String get displaySender {
    if (senderName.trim().isNotEmpty) return senderName;
    return 'Sistem';
  }

  String get displaySenderRole {
    if (senderRole.trim().isNotEmpty) return senderRole;
    return 'system';
  }

  String get displayType {
    if (type.trim().isNotEmpty) return type;
    if (refType.trim().isNotEmpty) return refType;
    return 'notification';
  }

  String get dedupeKey {
    final company = companyId.trim();
    final user = uid.trim();
    final ref = refType.trim();
    final refIdValue = refId.trim();
    final notifId = id.trim();

    if (company.isNotEmpty &&
        user.isNotEmpty &&
        ref.isNotEmpty &&
        refIdValue.isNotEmpty) {
      return '${company.toLowerCase()}|${user.toLowerCase()}|${ref.toLowerCase()}|${refIdValue.toLowerCase()}';
    }

    if (company.isNotEmpty && user.isNotEmpty && notifId.isNotEmpty) {
      return '${company.toLowerCase()}|${user.toLowerCase()}|${notifId.toLowerCase()}';
    }

    return [
      company.toLowerCase(),
      user.toLowerCase(),
      ref.toLowerCase(),
      refIdValue.toLowerCase(),
      notifId.toLowerCase(),
      createdAt.toString(),
      title.toLowerCase(),
    ].where((part) => part.isNotEmpty).join('|');
  }

  static String _firstNonEmpty(
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
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is String) return int.tryParse(value) ?? fallback;
    return int.tryParse(value.toString()) ?? fallback;
  }

  static bool _asBool(dynamic value, [bool fallback = false]) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return fallback;
    return text == 'true' || text == '1' || text == 'yes' || text == 'y';
  }

  static String _dateFromTimestamp(int timestamp) {
    if (timestamp <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return [
      date.year.toString().padLeft(4, '0'),
      date.month.toString().padLeft(2, '0'),
      date.day.toString().padLeft(2, '0'),
    ].join('-');
  }

  static String _timeFromTimestamp(int timestamp) {
    if (timestamp <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return [
      date.hour.toString().padLeft(2, '0'),
      date.minute.toString().padLeft(2, '0'),
    ].join(':');
  }
}
