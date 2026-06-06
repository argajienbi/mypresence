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
    required