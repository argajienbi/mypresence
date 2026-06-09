import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id, companyId, uid, title, body, message, type, refType, refId, relatedId, senderUid, senderName, senderRole, createdDate, createdTime;
  final bool read;
  final int createdAt;
  final Map<String, dynamic> raw;

  const AppNotification({