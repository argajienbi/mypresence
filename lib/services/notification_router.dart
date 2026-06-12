import 'package:flutter/material.dart';

import '../core/models/app_notification.dart';
import '../core/models/app_session.dart';
import '../features/announcements/announcements_page.dart';
import '../features/history/history_page.dart';
import '../features/home/main_shell.dart';
import '../features/notifications/notifications_page.dart';
import '../features/requests/request_status_page.dart';
import '../features/schedule/schedule_detail_page.dart';
import 'schedule_service.dart';

class NotificationRouter {
  const NotificationRouter._();

  static void openFromPayload(
    BuildContext context,
    AppSession session,
    Map<String, dynamic> payload,
  ) {
    final refType = (payload['ref_type'] ?? payload['type'] ?? '').toString();
    final refId = (payload['ref_id'] ?? payload['related_id'] ?? '').toString();
    final title =
        (payload['title'] ?? payload['notification_title'] ?? '').toString();
    final body = (payload['body'] ??
            payload['message'] ??
            payload['notification_body'] ??
            '')
        .toString();
    _routeByRefType(
      context,
      session,
      refType,
      refId: refId,
      title: title,
      body: body,
    );
  }

  static void openReference(
    BuildContext context,
    AppSession session,
    String? refType,
    String? refId,
  ) {
    _routeByRefType(
      context,
      session,
      refType ?? '',
      refId: refId ?? '',
    );
  }

  static void openFromNotification(
    BuildContext context,
    AppSession session,
    AppNotification notification,
  ) {
    _routeByRefType(
      context,
      session,
      notification.refType,
      refId: notification.refId,
      title: notification.title,
      body: notification.displayBody,
    );
  }

  static void _routeByRefType(
    BuildContext context,
    AppSession session,
    String refType, {
    String refId = '',
    String title = '',
    String body = '',
  }) {
    final type = refType.toLowerCase();
    final text = '$type $title $body'.toLowerCase();

    if (type.contains('announcement') || text.contains('pengumuman')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AnnouncementsPage(session: session)),
      );
      return;
    }

    if (type.contains('attendance_reminder') ||
        type.contains('reminder') ||
        text.contains('pengingat')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MainShell(session: session, initialIndex: 1)),
      );
      return;
    }

    if (_isRequestStatusType(type, text)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RequestStatusPage(
            session: session,
            initialType: _requestTypeFromText(type, text),
            initialStatus: _requestStatusFromText(type, text),
            highlightRefId: refId.trim().isEmpty ? null : refId.trim(),
          ),
        ),
      );
      return;
    }

    if (type.contains('schedule') ||
        type.contains('jadwal') ||
        text.contains('jadwal')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScheduleDetailPage(
            session: session,
            scheduleService: ScheduleService(),
            initialDate: DateTime.now(),
          ),
        ),
      );
      return;
    }

    if (type.contains('qr') || text.contains('qr')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RequestStatusPage(
            session: session,
            initialType: RequestTypeFilter.qr,
            highlightRefId: refId.trim().isEmpty ? null : refId.trim(),
          ),
        ),
      );
      return;
    }

    if (type.contains('attendance') ||
        type.contains('presensi') ||
        type.contains('absensi') ||
        text.contains('presensi')) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HistoryPage(session: session)),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NotificationsPage(session: session)),
    );
  }

  static bool _isRequestStatusType(String type, String text) {
    return type.contains('leave') ||
        type.contains('approval') ||
        type.contains('izin') ||
        type.contains('cuti') ||
        type.contains('sakit') ||
        type.contains('lembur') ||
        type.contains('overtime') ||
        type.contains('correction') ||
        type.contains('koreksi') ||
        text.contains('leave') ||
        text.contains('approval') ||
        text.contains('izin') ||
        text.contains('cuti') ||
        text.contains('sakit') ||
        text.contains('lembur') ||
        text.contains('overtime') ||
        text.contains('correction') ||
        text.contains('koreksi') ||
        text.contains('disetujui') ||
        text.contains('ditolak');
  }

  static RequestTypeFilter? _requestTypeFromText(String type, String text) {
    if (type.contains('correction') ||
        type.contains('koreksi') ||
        text.contains('correction') ||
        text.contains('koreksi')) {
      return RequestTypeFilter.correction;
    }

    if (type.contains('qr') || text.contains('qr')) {
      return RequestTypeFilter.qr;
    }

    if (type.contains('lembur') ||
        type.contains('overtime') ||
        text.contains('lembur') ||
        text.contains('overtime')) {
      return RequestTypeFilter.lembur;
    }

    if (type.contains('sakit') || text.contains('sakit')) {
      return RequestTypeFilter.sakit;
    }

    if (type.contains('cuti') || text.contains('cuti')) {
      return RequestTypeFilter.cuti;
    }

    if (type.contains('izin') || text.contains('izin')) {
      return RequestTypeFilter.izin;
    }

    return null;
  }

  static RequestStatusFilter? _requestStatusFromText(String type, String text) {
    if (text.contains('rejected') ||
        text.contains('ditolak') ||
        text.contains('declined') ||
        text.contains('cancelled')) {
      return RequestStatusFilter.rejected;
    }

    if (text.contains('approved') ||
        text.contains('disetujui') ||
        text.contains('validated') ||
        text.contains('success') ||
        text.contains('done')) {
      return RequestStatusFilter.approved;
    }

    if (text.contains('pending') ||
        text.contains('menunggu') ||
        text.contains('review') ||
        text.contains('processing')) {
      return RequestStatusFilter.pending;
    }

    if (type.contains('approval') && !text.contains('approve')) {
      return null;
    }

    return null;
  }
}
