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
  final bool read;
  final int createdAt;
  final String createdDate;
  final String createdTime;
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
    required this.read,
    required this.createdAt,
    required this.createdDate,
    required this.createdTime,
    required this.raw,
  });

  factory AppNotification.fromMap(
    String id,
    Map<String, dynamic> data, {
    String fallbackCompanyId = '',
    String fallbackUid = '',
  }) {
    final normalized = Map<String, dynamic>.from(data);
    final notificationId = _firstNonEmpty(
        normalized,
        const [
          'notification_id',
          'notificationId',
          'inbox_id',
          'inboxId',
          'id',
        ],
        fallback: id);

    final companyId = _firstNonEmpty(
        normalized,
        const [
          'company_id',
          'companyId',
          'company',
        ],
        fallback: fallbackCompanyId);

    final uid = _firstNonEmpty(
        normalized,
        const [
          'uid',
          'user_id',
          'userId',
          'target_uid',
          'targetUid',
          'recipient_uid',
          'recipientUid',
        ],
        fallback: fallbackUid);

    final title = _firstNonEmpty(
        normalized,
        const [
          'title',
          'judul',
          'subject',
          'heading',
        ],
        fallback: 'MYPRESENSI');

    final body = _firstNonEmpty(normalized, const [
      'body',
      'message',
      'pesan',
      'description',
      'deskripsi',
      'content',
      'text',
    ]);

    final message = _firstNonEmpty(
        normalized,
        const [
          'message',
          'body',
          'pesan',
          'description',
          'deskripsi',
          'content',
          'text',
        ],
        fallback: body);

    final type = _firstNonEmpty(
        normalized,
        const [
          'type',
          'notification_type',
          'notificationType',
          'category',
          'kind',
          'status',
        ],
        fallback: 'info');

    final refType = _firstNonEmpty(normalized, const [
      'ref_type',
      'refType',
      'reference_type',
      'referenceType',
      'source_type',
      'sourceType',
    ]);

    final refId = _firstNonEmpty(normalized, const [
      'ref_id',
      'refId',
      'reference_id',
      'referenceId',
      'source_id',
      'sourceId',
      'related_id',
      'relatedId',
    ]);

    final relatedId = _firstNonEmpty(
        normalized,
        const [
          'related_id',
          'relatedId',
          'ref_id',
          'refId',
          'reference_id',
          'referenceId',
        ],
        fallback: refId);

    final senderUid = _firstNonEmpty(normalized, const [
      'sender_uid',
      'senderUid',
      'created_by',
      'createdBy',
      'admin_uid',
      'adminUid',
      'from_uid',
      'fromUid',
    ]);

    final senderName = _firstNonEmpty(normalized, const [
      'sender_name',
      'senderName',
      'created_by_name',
      'createdByName',
      'admin_name',
      'adminName',
      'from_name',
      'fromName',
      'author',
    ]);

    final senderRole = _firstNonEmpty(normalized, const [
      'sender_role',
      'senderRole',
      'role',
      'created_by_role',
      'createdByRole',
      'from_role',
      'fromRole',
    ]);

    final createdAt = _readTimestamp(normalized);
    final createdDate = _firstNonEmpty(
        normalized,
        const [
          'created_date',
          'createdDate',
          'date',
          'tanggal',
        ],
        fallback: _dateFromMillis(createdAt));

    final createdTime = _firstNonEmpty(
        normalized,
        const [
          'created_time',
          'createdTime',
          'time',
          'jam',
        ],
        fallback: _timeFromMillis(createdAt));

    final read = _readBool(normalized, const [
      'read',
      'is_read',
      'isRead',
      'seen',
      'opened',
    ]);

    normalized['id'] = notificationId;
    normalized['notification_id'] = notificationId;
    normalized['company_id'] = companyId;
    normalized['uid'] = uid;
    normalized['title'] = title;
    normalized['body'] = body;
    normalized['message'] = message;
    normalized['type'] = type;
    normalized['ref_type'] = refType;
    normalized['ref_id'] = refId;
    normalized['related_id'] = relatedId;
    normalized['sender_uid'] = senderUid;
    normalized['sender_name'] = senderName;
    normalized['sender_role'] = senderRole;
    normalized['read'] = read;
    normalized['is_read'] = read;
    normalized['created_at'] = createdAt;
    normalized['created_date'] = createdDate;
    normalized['created_time'] = createdTime;

    return AppNotification(
      id: notificationId,
      companyId: companyId,
      uid: uid,
      title: title,
      body: body,
      message: message,
      type: type,
      refType: refType,
      refId: refId,
      relatedId: relatedId,
      senderUid: senderUid,
      senderName: senderName,
      senderRole: senderRole,
      read: read,
      createdAt: createdAt,
      createdDate: createdDate,
      createdTime: createdTime,
      raw: normalized,
    );
  }

  String get displayBody {
    final value = body.trim().isNotEmpty ? body : message;
    if (value.trim().isNotEmpty) return value.trim();

    final fallback = _firstNonEmpty(raw, const [
      'description',
      'deskripsi',
      'content',
      'text',
      'subtitle',
    ]);

    return fallback.trim().isNotEmpty
        ? fallback.trim()
        : 'Ada notifikasi baru.';
  }

  String get displayType {
    final value = '$type $refType $title $displayBody'.toLowerCase();

    if (value.contains('attendance_reminder') || value.contains('reminder')) {
      return 'Pengingat';
    }

    if (value.contains('schedule') || value.contains('jadwal')) {
      return 'Jadwal';
    }

    if (value.contains('correction') || value.contains('koreksi')) {
      return 'Koreksi';
    }

    if (value.contains('attendance') ||
        value.contains('presensi') ||
        value.contains('absensi') ||
        value.contains('qr')) {
      return 'Presensi';
    }

    if (value.contains('approval') ||
        value.contains('approved') ||
        value.contains('rejected') ||
        value.contains('leave') ||
        value.contains('izin') ||
        value.contains('sakit') ||
        value.contains('cuti') ||
        value.contains('lembur') ||
        value.contains('overtime')) {
      return 'Approval';
    }

    if (value.contains('announcement') || value.contains('pengumuman')) {
      return 'Pengumuman';
    }

    if (value.contains('system') ||
        value.contains('sistem') ||
        value.contains('user_status') ||
        value.contains('status_update')) {
      return 'Sistem';
    }

    if (type.trim().isEmpty) return 'Info';

    return _titleCase(type.replaceAll('_', ' '));
  }

  String get displaySender {
    if (senderName.trim().isNotEmpty) return senderName.trim();
    if (senderUid.trim().isNotEmpty) return senderUid.trim();

    final fallback = _firstNonEmpty(raw, const [
      'created_by_name',
      'createdByName',
      'admin_name',
      'adminName',
      'from_name',
      'fromName',
      'author',
    ]);

    return fallback.trim().isNotEmpty ? fallback.trim() : 'Sistem';
  }

  String get displaySenderRole {
    if (senderRole.trim().isNotEmpty) {
      return _titleCase(senderRole.replaceAll('_', ' '));
    }

    final fallback = _firstNonEmpty(raw, const [
      'role',
      'created_by_role',
      'createdByRole',
      'from_role',
      'fromRole',
    ]);

    return fallback.trim().isNotEmpty
        ? _titleCase(fallback.replaceAll('_', ' '))
        : 'Sistem';
  }

  String get dedupeKey {
    final notificationId = _firstNonEmpty(raw, const [
      'notification_id',
      'notificationId',
      'inbox_id',
      'inboxId',
      'id',
    ]);

    if (notificationId.trim().isNotEmpty) {
      return 'notification:$notificationId';
    }

    if (refType.trim().isNotEmpty ||
        refId.trim().isNotEmpty ||
        relatedId.trim().isNotEmpty) {
      return 'ref:$companyId:$uid:$refType:${refId.trim().isNotEmpty ? refId : relatedId}:$createdAt';
    }

    return 'id:$id';
  }

  bool get isUnread => !read;

  Map<String, dynamic> toMap() {
    return {
      ...raw,
      'id': id,
      'notification_id': id,
      'company_id': companyId,
      'uid': uid,
      'title': title,
      'body': body,
      'message': message,
      'type': type,
      'ref_type': refType,
      'ref_id': refId,
      'related_id': relatedId,
      'sender_uid': senderUid,
      'sender_name': senderName,
      'sender_role': senderRole,
      'read': read,
      'is_read': read,
      'created_at': createdAt,
      'created_date': createdDate,
      'created_time': createdTime,
    };
  }

  AppNotification copyWith({
    String? id,
    String? companyId,
    String? uid,
    String? title,
    String? body,
    String? message,
    String? type,
    String? refType,
    String? refId,
    String? relatedId,
    String? senderUid,
    String? senderName,
    String? senderRole,
    bool? read,
    int? createdAt,
    String? createdDate,
    String? createdTime,
    Map<String, dynamic>? raw,
  }) {
    return AppNotification(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      body: body ?? this.body,
      message: message ?? this.message,
      type: type ?? this.type,
      refType: refType ?? this.refType,
      refId: refId ?? this.refId,
      relatedId: relatedId ?? this.relatedId,
      senderUid: senderUid ?? this.senderUid,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      createdDate: createdDate ?? this.createdDate,
      createdTime: createdTime ?? this.createdTime,
      raw: raw ?? this.raw,
    );
  }

  static String _firstNonEmpty(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];
      final text = _stringValue(value).trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return fallback;
  }

  static String _stringValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }

  static bool _readBool(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (!data.containsKey(key)) continue;
      final value = data[key];

      if (value is bool) return value;
      if (value is num) return value != 0;

      final text = value?.toString().trim().toLowerCase() ?? '';
      if (text == 'true' || text == '1' || text == 'yes' || text == 'y')
        return true;
      if (text == 'false' || text == '0' || text == 'no' || text == 'n')
        return false;
    }

    return false;
  }

  static int _readTimestamp(Map<String, dynamic> data) {
    final direct = _timestampFromValue(data['created_at']);
    if (direct > 0) return direct;

    final createdAtCamel = _timestampFromValue(data['createdAt']);
    if (createdAtCamel > 0) return createdAtCamel;

    final updatedAt = _timestampFromValue(data['updated_at']);
    if (updatedAt > 0) return updatedAt;

    final timestamp = _timestampFromValue(data['timestamp']);
    if (timestamp > 0) return timestamp;

    final sentAt = _timestampFromValue(data['sent_at']);
    if (sentAt > 0) return sentAt;

    final failedAt = _timestampFromValue(data['failed_at']);
    if (failedAt > 0) return failedAt;

    final date = _firstNonEmpty(data, const [
      'created_date',
      'createdDate',
      'date',
      'tanggal',
    ]);

    final time = _firstNonEmpty(data, const [
      'created_time',
      'createdTime',
      'time',
      'jam',
    ]);

    final fromParts = _timestampFromDateParts(date, time);
    if (fromParts > 0) return fromParts;

    return DateTime.now().millisecondsSinceEpoch;
  }

  static int _timestampFromValue(dynamic value) {
    if (value == null) return 0;

    if (value is Timestamp) {
      return value.toDate().millisecondsSinceEpoch;
    }

    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }

    if (value is int) {
      if (value <= 0) return 0;
      if (value < 10000000000) return value * 1000;
      return value;
    }

    if (value is double) {
      if (value <= 0) return 0;
      final rounded = value.round();
      if (rounded < 10000000000) return rounded * 1000;
      return rounded;
    }

    if (value is Map) {
      final seconds = value['seconds'] ?? value['_seconds'];
      final nanos = value['nanoseconds'] ?? value['_nanoseconds'];
      final sec = int.tryParse(seconds?.toString() ?? '');
      final nano = int.tryParse(nanos?.toString() ?? '') ?? 0;

      if (sec != null && sec > 0) {
        return (sec * 1000) + (nano ~/ 1000000);
      }
    }

    final text = value.toString().trim();
    if (text.isEmpty) return 0;

    final asInt = int.tryParse(text);
    if (asInt != null) {
      if (asInt <= 0) return 0;
      if (asInt < 10000000000) return asInt * 1000;
      return asInt;
    }

    final parsed = DateTime.tryParse(text);
    if (parsed != null) {
      return parsed.millisecondsSinceEpoch;
    }

    return 0;
  }

  static int _timestampFromDateParts(String date, String time) {
    final cleanDate = date.trim();
    if (cleanDate.isEmpty) return 0;

    final dateParts = cleanDate.split('-');
    if (dateParts.length != 3) return 0;

    final year = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final day = int.tryParse(dateParts[2]);

    if (year == null || month == null || day == null) return 0;

    final cleanTime = time.trim().isEmpty ? '00:00:00' : time.trim();
    final timeParts = cleanTime.split(':');

    final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
    final second = timeParts.length > 2 ? int.tryParse(timeParts[2]) ?? 0 : 0;

    return DateTime(year, month, day, hour, minute, second)
        .millisecondsSinceEpoch;
  }

  static String _dateFromMillis(int millis) {
    if (millis <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _timeFromMillis(int millis) {
    if (millis <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';
  }

  static String _titleCase(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return clean;

    return clean
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
      final lower = part.toLowerCase();
      return lower[0].toUpperCase() + lower.substring(1);
    }).join(' ');
  }
}
