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