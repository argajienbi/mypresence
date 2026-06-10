import 'package:intl/intl.dart';

import '../core/firebase_paths.dart';
import '../core/models/app_session.dart';
import '../core/models/attendance_correction_request.dart';
import '../core/models/request_status_item.dart';
import '../core/utils.dart';
import 'rtdb_service.dart';

class RequestStatusService {
  final RtdbService _rtdb = RtdbService();

  Future<List<RequestStatusItem>> loadRequests(AppSession session) async {
    final results = await Future.wait([
      _rtdb.getMap(FirebasePaths.leaveRequests(session.companyId)),
      _rtdb.getMap(FirebasePaths.qrRequests(session.companyId)),
      _rtdb.getMap(FirebasePaths.attendanceCorrections(session.companyId)),
    ]);

    final items = <RequestStatusItem>[];
    items.addAll(_loadLeaveRequests(session, results[0]));
    items.addAll(_loadQrRequests(session, results[1]));
    items.addAll(_loadCorrections(session, results[2]));
    items.sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
    return items;
  }

  List<RequestStatusItem> _loadLeaveRequests(
    AppSession session,
    Map<String, dynamic>? root,
  ) {
    final rows = <RequestStatusItem>[];
    final map = root ?? <String, dynamic>{};
    for (final entry in map.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final row = asMap(value);
      if (asString(row['uid']) != session.uid) continue;

      final type = _leaveType(row);
      final rawStatus = asString(row['status'], 'pending');
      final status = RequestStatusItem.normalizeStatus(rawStatus);
      final createdAt = _createdAt(row);
      final processedAt = _processedAt(row, status);
      final dateLabel = _leaveDateLabel(row);
      final note = asString(row['reason'], asString(row['alasan']));
      final adminNote = asString(row['admin_note']);
      final evidenceUrl = asString(row['attachment_url']);
      final evidencePath = asString(row['attachment_path']);
      rows.add(
        RequestStatusItem(
          id: entry.key,
          kind: RequestStatusKind.leave,
          kindLabel: type,
          contextLabel: '',
          status: status,
          rawStatus: rawStatus,
          createdAtMillis: createdAt,
          createdAtLabel: _formatDateTime(createdAt),
          processedAtMillis: processedAt,
          processedAtLabel: _formatDateTime(processedAt),
          targetDateLabel: dateLabel,
          note: note,
          adminNote: adminNote,
          evidenceLabel: 'Lampiran',
          evidenceUrl: evidenceUrl,
          evidencePath: evidencePath,
          targetUid: asString(row['uid']),
          targetName: asString(row['user_name']),
          helperUid: '',
          helperName: '',
          actionType: asString(row['type']),
          raw: row,
        ),
      );
    }
    return rows;
  }

  List<RequestStatusItem> _loadQrRequests(
    AppSession session,
    Map<String, dynamic>? root,
  ) {
    final rows = <RequestStatusItem>[];
    final map = root ?? <String, dynamic>{};
    for (final entry in map.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final row = asMap(value);
      final targetUid = asString(row['target_uid']);
      final helperUid = asString(row['helper_uid']);
      final matchesTarget = targetUid == session.uid;
      final matchesHelper = helperUid == session.uid;
      if (!matchesTarget && !matchesHelper) continue;

      final rawStatus = asString(row['status'], 'pending');
      final status = RequestStatusItem.normalizeStatus(rawStatus);
      final createdAt = _createdAt(row);
      final processedAt = _processedAt(row, status);
      final action = _actionLabel(asString(row['action_type']));
      final contextLabel = matchesTarget && matchesHelper
          ? 'Sebagai Target & Helper'
          : matchesTarget
              ? 'Sebagai Target'
              : 'Sebagai Helper';
      final note = matchesTarget
          ? _helperText(row)
          : _targetText(row);
      rows.add(
        RequestStatusItem(
          id: entry.key,
          kind: matchesTarget
              ? RequestStatusKind.qrTarget
              : RequestStatusKind.qrHelper,
          kindLabel: 'QR Titip Absen',
          contextLabel: contextLabel,
          status: status,
          rawStatus: rawStatus,
          createdAtMillis: createdAt,
          createdAtLabel: _formatDateTime(createdAt),
          processedAtMillis: processedAt,
          processedAtLabel: _formatDateTime(processedAt),
          targetDateLabel: _qrDateLabel(row),
          note: note,
          adminNote: asString(row['admin_note']),
          evidenceLabel: 'Foto bukti',
          evidenceUrl: asString(row['photo_url']),
          evidencePath: asString(row['photo_path']),
          targetUid: targetUid,
          targetName: asString(row['target_name']),
          helperUid: helperUid,
          helperName: asString(row['helper_name']),
          actionType: action,
          raw: row,
        ),
      );
    }
    return rows;
  }

  List<RequestStatusItem> _loadCorrections(
    AppSession session,
    Map<String, dynamic>? root,
  ) {
    final rows = <RequestStatusItem>[];
    final map = root ?? <String, dynamic>{};
    for (final entry in map.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final request = AttendanceCorrectionRequest.fromMap(entry.key, asMap(value));
      if (request.uid != session.uid) continue;

      final status = RequestStatusItem.normalizeStatus(request.status);
      rows.add(
        RequestStatusItem(
          id: request.correctionId,
          kind: RequestStatusKind.correction,
          kindLabel: 'Koreksi Presensi',
          contextLabel: '',
          status: status,
          rawStatus: request.status,
          createdAtMillis: request.createdAt,
          createdAtLabel: _formatDateTime(request.createdAt),
          processedAtMillis: _processedAtFromCorrection(request, status),
          processedAtLabel: _formatDateTime(_processedAtFromCorrection(request, status)),
          targetDateLabel: _dateLabel(request.date),
          note: request.reason,
          adminNote: request.adminNote,
          evidenceLabel: 'Lampiran',
          evidenceUrl: request.attachmentUrl,
          evidencePath: request.attachmentPath,
          targetUid: request.uid,
          targetName: request.userName,
          helperUid: '',
          helperName: '',
          actionType: request.correctionType,
          raw: request.toMap(),
        ),
      );
    }
    return rows;
  }

  String _leaveType(Map<String, dynamic> row) {
    switch (asString(row['type'], asString(row['leave_type'], 'izin')).toLowerCase()) {
      case 'sakit':
        return 'Sakit';
      case 'cuti':
        return 'Cuti';
      case 'lembur':
        return 'Lembur';
      default:
        return 'Izin';
    }
  }

  String _actionLabel(String raw) {
    final value = raw.toLowerCase();
    if (value == 'pulang') return 'Clock Out';
    return 'Clock In';
  }

  String _helperText(Map<String, dynamic> row) {
    final helper = asString(row['helper_name']);
    if (helper.isNotEmpty) {
      return 'Dibantu oleh $helper';
    }
    return 'Dibantu oleh karyawan lain';
  }

  String _targetText(Map<String, dynamic> row) {
    final target = asString(row['target_name']);
    if (target.isNotEmpty) {
      return 'Untuk $target';
    }
    return 'Untuk karyawan lain';
  }

  String _qrDateLabel(Map<String, dynamic> row) {
    final date = DateTime.tryParse(asString(row['date'], asString(row['tanggal'])));
    final time = asString(row['time'], asString(row['waktu']));
    if (date == null) {
      return time.isEmpty ? '-' : time;
    }
    final formatted = _dateLabel(AppDate.dateKey(date));
    if (time.isEmpty) {
      return formatted;
    }
    return '$formatted - $time';
  }

  String _leaveDateLabel(Map<String, dynamic> row) {
    final type = asString(row['type'], asString(row['leave_type'], 'izin')).toLowerCase();
    if (type == 'lembur') {
      final date = _dateLabel(asString(row['overtime_date'], asString(row['date_start'], asString(row['date']))));
      final start = asString(row['overtime_start_time']);
      final end = asString(row['overtime_end_time']);
      if (start.isNotEmpty && end.isNotEmpty) {
        return '$date - $start - $end';
      }
      return date;
    }

    final startRaw = asString(row['date_start'], asString(row['tanggal_mulai'], asString(row['date'])));
    final endRaw = asString(row['date_end'], asString(row['tanggal_selesai'], startRaw));
    final start = _dateLabel(startRaw);
    final end = _dateLabel(endRaw);
    if (start == end) {
      return start;
    }
    return '$start - $end';
  }

  int _createdAt(Map<String, dynamic> row) {
    return asInt(row['created_at'], asInt(row['timestamp'], asInt(row['updated_at'])));
  }

  int _processedAt(Map<String, dynamic> row, String status) {
    switch (status) {
      case 'approved':
        return asInt(row['validated_at'], asInt(row['approved_at'], asInt(row['updated_at'])));
      case 'rejected':
        return asInt(row['rejected_at'], asInt(row['updated_at']));
      default:
        return 0;
    }
  }

  int _processedAtFromCorrection(AttendanceCorrectionRequest request, String status) {
    switch (status) {
      case 'approved':
        return request.validatedAt > 0
            ? request.validatedAt
            : (request.approvedAt > 0 ? request.approvedAt : request.updatedAt);
      case 'rejected':
        return request.rejectedAt > 0 ? request.rejectedAt : request.updatedAt;
      default:
        return 0;
    }
  }

  String _dateLabel(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }

  String _formatDateTime(int millis) {
    if (millis <= 0) return '';
    return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(
      DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }
}
