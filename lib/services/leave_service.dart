import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../core/firebase_paths.dart';
import '../core/models/app_session.dart';
import 'rtdb_service.dart';

class LeaveService {
  final RtdbService _rtdb = RtdbService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> submitLeave({
    required AppSession session,
    required String type,
    required String dateStart,
    required String dateEnd,
    required String reason,
    File? attachmentFile,
    String attachmentName = '',
    String overtimeDate = '',
    String overtimeStartTime = '',
    String overtimeEndTime = '',
    int overtimeDurationMinute = 0,
  }) async {
    final normalizedType = type.trim().toLowerCase();
    final normalizedStart = dateStart.trim();
    final normalizedEnd = dateEnd.trim();
    final normalizedReason = reason.trim();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final requestId = 'leave_$ts';

    if (normalizedStart.isEmpty || normalizedEnd.isEmpty) {
      throw Exception('Tanggal mulai dan tanggal selesai wajib diisi.');
    }
    if (normalizedReason.isEmpty) {
      throw Exception(normalizedType == 'lembur' ? 'Alasan / pekerjaan lembur wajib diisi.' : 'Alasan wajib diisi.');
    }

    final startDate = DateTime.tryParse(normalizedStart);
    final endDate = DateTime.tryParse(normalizedEnd);
    if (startDate == null || endDate == null) {
      throw Exception('Format tanggal tidak valid. Gunakan yyyy-mm-dd.');
    }
    if (endDate.isBefore(startDate)) {
      throw Exception('Tanggal selesai tidak boleh lebih awal dari tanggal mulai.');
    }

    if (normalizedType == 'sakit' && attachmentFile == null) {
      throw Exception('Bukti sakit wajib dilampirkan.');
    }

    if (normalizedType == 'lembur') {
      if (overtimeDate.trim().isEmpty || overtimeStartTime.trim().isEmpty || overtimeEndTime.trim().isEmpty) {
        throw Exception('Tanggal, jam mulai, dan jam selesai lembur wajib diisi.');
      }
      if (overtimeDurationMinute <= 0) {
        throw Exception('Jam selesai lembur harus lebih besar dari jam mulai.');
      }
    }

    await _ensureNoActiveOverlap(
      session: session,
      type: normalizedType,
      dateStart: normalizedStart,
      dateEnd: normalizedEnd,
      overtimeDate: overtimeDate.trim(),
      overtimeStartTime: overtimeStartTime.trim(),
      overtimeEndTime: overtimeEndTime.trim(),
    );

    String attachmentUrl = '';
    String attachmentPath = '';
    String savedAttachmentName = '';
    if (attachmentFile != null) {
      savedAttachmentName = attachmentName.isEmpty ? 'attachment_$ts.jpg' : attachmentName;
      attachmentPath = FirebasePaths.leaveAttachment(session.companyId, session.uid, requestId, savedAttachmentName);
      final ref = _storage.ref(attachmentPath);
      await ref.putFile(attachmentFile);
      attachmentUrl = await ref.getDownloadURL();
    }

    final payload = {
      'request_id': requestId,
      'company_id': session.companyId,
      'uid': session.uid,
      'user_name': session.displayName,
      'nip': session.nip,
      'type': normalizedType,
      'date_start': normalizedStart,
      'date_end': normalizedEnd,
      'reason': normalizedReason,
      'attachment_url': attachmentUrl,
      'attachment_path': attachmentPath,
      'attachment_name': savedAttachmentName,
      'attachment_required': normalizedType == 'sakit',
      'attachment_type': attachmentFile == null ? '' : 'image',
      'overtime_date': normalizedType == 'lembur' ? overtimeDate.trim() : '',
      'overtime_start_time': normalizedType == 'lembur' ? overtimeStartTime.trim() : '',
      'overtime_end_time': normalizedType == 'lembur' ? overtimeEndTime.trim() : '',
      'overtime_duration_minute': normalizedType == 'lembur' ? overtimeDurationMinute : 0,
      'status': 'pending',
      'admin_uid': '',
      'admin_name': '',
      'admin_note': '',
      'validated_at': 0,
      'approved_by': '',
      'approved_by_name': '',
      'approved_at': 0,
      'rejected_by': '',
      'rejected_by_name': '',
      'rejected_at': 0,
      'office_id': session.officeId,
      'office_name': session.officeName,
      'department_id': session.departmentId,
      'department_name': session.departmentName,
      'sub_department_id': session.subDepartmentId,
      'sub_department_name': session.subDepartmentName,
      'group_id': session.groupId,
      'group_name': session.groupName,
      'created_at': ts,
      'updated_at': ts,
    };
    await _rtdb.set(FirebasePaths.leaveRequest(session.companyId, requestId), payload);
  }

  Future<void> _ensureNoActiveOverlap({
    required AppSession session,
    required String type,
    required String dateStart,
    required String dateEnd,
    required String overtimeDate,
    required String overtimeStartTime,
    required String overtimeEndTime,
  }) async {
    final root = await _rtdb.getMap(FirebasePaths.leaveRequests(session.companyId)) ?? <String, dynamic>{};
    final start = DateTime.parse(dateStart);
    final end = DateTime.parse(dateEnd);

    for (final entry in root.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final map = value.map((k, v) => MapEntry(k.toString(), v));
      if ((map['uid'] ?? '').toString() != session.uid) continue;
      if ((map['type'] ?? '').toString().toLowerCase() != type) continue;
      if (!_isActiveRequest((map['status'] ?? '').toString())) continue;

      if (type == 'lembur') {
        final existingDate = (map['overtime_date'] ?? map['date_start'] ?? '').toString();
        final existingStart = (map['overtime_start_time'] ?? '').toString();
        final existingEnd = (map['overtime_end_time'] ?? '').toString();
        if (existingDate == overtimeDate && existingStart.isNotEmpty && existingEnd.isNotEmpty) {
          if (_timeRangeOverlap(overtimeStartTime, overtimeEndTime, existingStart, existingEnd)) {
            throw Exception('Sudah ada pengajuan lembur aktif yang overlap pada tanggal dan jam tersebut.');
          }
        }
        continue;
      }

      final existingStart = DateTime.tryParse((map['date_start'] ?? map['date'] ?? '').toString());
      final existingEnd = DateTime.tryParse((map['date_end'] ?? map['date_start'] ?? map['date'] ?? '').toString());
      if (existingStart == null || existingEnd == null) continue;
      if (_dateRangeOverlap(start, end, existingStart, existingEnd)) {
        throw Exception('Sudah ada pengajuan ${_typeLabel(type)} aktif pada rentang tanggal tersebut.');
      }
    }
  }

  bool _isActiveRequest(String status) {
    final normalized = status.toLowerCase();
    return normalized == 'pending' || normalized == 'approved' || normalized == 'validated' || normalized == 'processing';
  }

  bool _isApprovedRequest(String status) {
    final normalized = status.toLowerCase();
    return normalized == 'approved' || normalized == 'validated';
  }

  bool _dateRangeOverlap(DateTime startA, DateTime endA, DateTime startB, DateTime endB) {
    return !startA.isAfter(endB) && !startB.isAfter(endA);
  }

  bool _timeRangeOverlap(String startA, String endA, String startB, String endB) {
    final aStart = _minuteOfDay(startA);
    final aEnd = _minuteOfDay(endA);
    final bStart = _minuteOfDay(startB);
    final bEnd = _minuteOfDay(endB);
    if (aStart == null || aEnd == null || bStart == null || bEnd == null) return false;
    return aStart < bEnd && bStart < aEnd;
  }

  int? _minuteOfDay(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return (hour * 60) + minute;
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'sakit':
        return 'sakit';
      case 'cuti':
        return 'cuti';
      case 'lembur':
        return 'lembur';
      default:
        return 'izin';
    }
  }

  Future<Map<String, dynamic>?> getApprovedLeaveForDate({required AppSession session, required DateTime date}) async {
    final key = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final root = await _rtdb.getMap(FirebasePaths.leaveRequests(session.companyId)) ?? <String, dynamic>{};
    for (final entry in root.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final map = value.map((k, v) => MapEntry(k.toString(), v));
      if ((map['uid'] ?? '').toString() != session.uid) continue;
      final type = (map['type'] ?? map['leave_type'] ?? '').toString().toLowerCase();
      if (type == 'lembur') continue;
      if (type != 'izin' && type != 'sakit' && type != 'cuti') continue;
      if (!_isApprovedRequest((map['status'] ?? '').toString())) continue;
      final start = DateTime.tryParse((map['date_start'] ?? map['tanggal_mulai'] ?? map['date'] ?? '').toString());
      final end = DateTime.tryParse((map['date_end'] ?? map['tanggal_selesai'] ?? map['date_start'] ?? map['tanggal_mulai'] ?? map['date'] ?? '').toString());
      final target = DateTime.tryParse(key);
      if (start == null || end == null || target == null) continue;
      if (_dateRangeOverlap(target, target, start, end)) {
        return {'request_id': entry.key, ...map};
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getMonthlyRequests({required AppSession session, required DateTime month}) async {
    final root = await _rtdb.getMap(FirebasePaths.leaveRequests(session.companyId)) ?? <String, dynamic>{};
    final rows = <Map<String, dynamic>>[];
    for (final entry in root.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final map = value.map((k, v) => MapEntry(k.toString(), v));
      if ((map['uid'] ?? '').toString() != session.uid) continue;
      if (!_isApprovedRequest((map['status'] ?? '').toString())) continue;
      final type = (map['type'] ?? map['leave_type'] ?? '').toString().toLowerCase();
      if (type == 'lembur') continue;
      final start = DateTime.tryParse((map['date_start'] ?? map['tanggal_mulai'] ?? map['date'] ?? '').toString());
      if (start == null || start.year != month.year || start.month != month.month) continue;
      rows.add({'request_id': entry.key, ...map});
    }
    rows.sort((a, b) => (b['date_start'] ?? b['tanggal_mulai'] ?? b['date'] ?? '').toString().compareTo((a['date_start'] ?? a['tanggal_mulai'] ?? a['date'] ?? '').toString()));
    return rows;
  }
}
