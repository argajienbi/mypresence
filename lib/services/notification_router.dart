import 'package:flutter/material.dart';

import '../core/models/app_notification.dart';
import '../core/models/app_session.dart';
import '../features/announcements/announcements_page.dart';
import '../features/home/main_shell.dart';
import '../features/notifications/notifications_page.dart';

class NotificationRouter {
  const NotificationRouter._();

  static void openFromPayload(
    BuildContext context,
    AppSession session,
    Map<String, dynamic> payload,
  ) {
    final refType = (payload['ref_type'] ?? payload['type'] ?? '').toString();
    _routeByRefType(context, session, refType);
  }


  static void openReference(
    BuildContext context,
    AppSession session,
    String? refType,
    String? refId,
  ) {
    _routeByRefType(context, session, refType ?? '');
  }

  static void openFromNotification(
    BuildContext context,
    AppSession session,
    AppNotification notification,
  ) {
    _routeByRefType(context, session, notification.refType);
  }

  static void _routeByRefType(
    BuildContext context,
    AppSession session,
    String refType,
  ) {
    final type = refType.toLowerCase();

    if (type.contains('announcement') || type.contains('holiday') || type.contains('schedule')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AnnouncementsPage(session: session)),
      );
      return;
    }

    if (type.contains('leave') || type.contains('qr') || type.contains('attendance')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MainShell(session: session, initialIndex: 0)),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NotificationsPage(session: session)),
    );
  }
}
