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
    final refId = (payload['ref_id'] ?? payload['related_id'] ?? '').toString();
    _routeByRefType(context, session, refType, refId: refId);
  }

  static void openReference(
    BuildContext context,
    AppSession session,
    String? refType,
    String? refId,
  ) {
    _routeByRefType(context, session, refType ?? '', refId: refId ?? '');
  }

  static void openFromNotification(
    BuildContext context,
    AppSession session,
    AppNotification notification,
  ) {
    _routeByRefType(context, session, notification.refType, refId: notification.refId);
  }

  static void _routeByRefType(
    BuildContext context,
    AppSession session,
    String refType, {
    String refId = '',
  }) {
    final type = refType.toLowerCase();

    if (type.contains('announcement')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AnnouncementsPage(session: session)),
      );
      return;
    }

    if (type.contains('attendance_reminder') || type.contains('reminder')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MainShell(session: session, initialIndex: 1)),
      );
      return;
    }

    if (type.contains('leave') || type.contains('approval')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MainShell(session: session, initialIndex: 0)),
      );
      return;
    }

    if (type.contains('qr') || type.contains('attendance')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MainShell(session: session, initialIndex: 0)),
      );
      return;
    }

    if (type.contains('schedule') || type.contains('jadwal') || type.contains('holiday')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MainShell(session: session, initialIndex: 1, showScheduleOnOpen: true)),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NotificationsPage(session: session)),
    );
  }
}
