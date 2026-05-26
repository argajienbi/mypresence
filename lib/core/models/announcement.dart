class Announcement {
  final String id;
  final String companyId;
  final String title;
  final String body;
  final String type;
  final String status;
  final String targetType;
  final List<String> targetIds;
  final bool sendPush;
  final bool active;
  final int publishedAt;
  final int scheduledAt;
  final int createdAt;
  final int updatedAt;
  final Map<String, dynamic> raw;

  const Announcement({
    required this.id,
    required this.companyId,
    required this.title,
    required this.body,
    required this.type,
    required this.status,
    required this.targetType,
    required this.targetIds,
    required this.sendPush,
    required this.active,
    required this.publishedAt,
    required this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
    required this.raw,
  });

  factory Announcement.fromMap(
    String id,
    Map<String, dynamic> data, {
    String fallbackCompanyId = '',
  }) {
    return Announcement(
      id: id,
      companyId: (data['company_id'] ?? fallbackCompanyId).toString(),
      title: (data['title'] ?? 'Pengumuman').toString(),
      body: (data['body'] ?? data['message'] ?? '').toString(),
      type: (data['type'] ?? 'info').toString(),
      status: (data['status'] ?? 'published').toString(),
      targetType: (data['target_type'] ?? 'all').toString(),
      targetIds: _toStringList(data['target_ids']),
      sendPush: data['send_push'] == true,
      active: data['active'] != false,
      publishedAt: _toInt(data['published_at']),
      scheduledAt: _toInt(data['scheduled_at']),
      createdAt: _toInt(data['created_at']),
      updatedAt: _toInt(data['updated_at']),
      raw: data,
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
