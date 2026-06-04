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
    final message = _firstString(data, const ['message', 'body', 'description']);
    final body = _firstString(data, const ['body', 'message', 'description']);
    final title = _firstString(data, const ['title', 'notification_title', 'subject']);
    final readValue = data['read'];
    final isReadValue = data['is_read'];
    final rawRefType = _string(data['ref_type']);

    return AppNotification(
      id: id,
      companyId: _string(data['company_id'], fallbackCompanyId),
      uid: _string(data['uid'], fallbackUid),
      title: title.isEmpty ? 'MYPRESENSI' : title,
      body: body,
      message: message,
      type: _string(data['type'], 'info'),
      refType: _normalizeRefType(rawRefType),
      refId: _string(data['ref_id'], _string(data['related_id'])),
      relatedId: _string(data['related_id'], _string(data['ref_id'])),
      senderUid: _string(data['sender_uid'], _string(data['created_by'])),
      senderName: _firstString(
        data,
        const ['sender_name', 'created_by_name', 'admin_name', 'from_name'],
        fallback: 'Admin',
      ),
      senderRole: _firstString(
        data,
        const ['sender_role', 'created_by_role', 'role'],
        fallback: 'admin',
      ),
      read: readValue == true || isReadValue == true,
      createdAt: _toInt(data['created_at']),
      createdDate: _string(data['created_date']),
      createdTime: _string(data['created_time']),
      raw: data,
    );
  }

  String get displayBody {
    final value = body.trim().isNotEmpty ? body.trim() : message.trim();
    return value.isEmpty ? 'Ada notifikasi baru.' : value;
  }

  String get displaySender => senderName.trim().isEmpty ? 'Admin' : senderName.trim();

  String get displaySenderRole {
    final value = senderRole.trim();
    if (value.isEmpty) return 'Admin';
    return value.replaceAll('_', ' ').toUpperCase();
  }

  String get displayType {
    final value = type.toLowerCase();
    final ref = refType.toLowerCase();
    if (ref.contains('announcement')) return 'Pengumuman';
    if (value.contains('success')) return 'Sukses';
    if (value.contains('warning')) return 'Peringatan';
    if (value.contains('danger') || value.contains('error')) return 'Penting';
    if (ref.contains('correction') || ref.contains('koreksi')) return 'Koreksi';
    if (ref.contains('approval') || value.contains('approval')) return 'Persetujuan';
    if (ref.contains('attendance') || value.contains('attendance')) return 'Absensi';
    if (ref.contains('schedule')) return 'Jadwal';
    if (ref.contains('leave')) return 'Pengajuan';
    return 'Informasi';
  }

  String get dedupeKey {
    if (refType.isNotEmpty && refId.isNotEmpty) {
      return '${refType.toLowerCase()}::$refId';
    }
    final notificationId = _string(raw['notification_id']);
    if (notificationId.isNotEmpty) return notificationId;
    return id;
  }

  static String _firstString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = _string(data[key]);
      if (value.trim().isNotEmpty) return value.trim();
    }
    return fallback;
  }

  static String _string(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    return value.toString();
  }

  static String _normalizeRefType(String raw) {
    final original = raw.trim();
    final value = original.toLowerCase();

    if (value.isEmpty) return original;
    if (value.contains('announcement') || value.contains('pengumuman')) return 'announcement';
    if (value.contains('correction') || value.contains('koreksi')) return 'attendance_correction';
    if (value.contains('approval')) return 'approval';
    if (value.contains('leave') ||
        value.contains('izin') ||
        value.contains('cuti') ||
        value.contains('sakit') ||
        value.contains('lembur') ||
        value.contains('overtime')) {
      return 'leave';
    }
    if (value.contains('schedule') || value.contains('jadwal') || value.contains('holiday')) return 'schedule';
    if (value.contains('attendance') || value.contains('presensi') || value.contains('qr')) return 'attendance';
    if (value.contains('system') || value.contains('sistem')) return 'system';

    return original;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
