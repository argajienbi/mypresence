import 'dart:io';

import '../core/firebase_paths.dart';
import '../core/models/app_session.dart';
import '../core/models/attendance_correction_request.dart';
import '../core/models/request_status_item.dart';
import '../core/utils.dart';
import 'rtdb_service.dart';
import 'storage_service.dart';

class AttendanceCorrectionService {
  final RtdbService _rtdb = RtdbService();
  final StorageService _storage = StorageService();

  Future<Map<String, dynamic>?> getAttendanceMap({
    required AppSession session,
    required String dateKey,
  }) async {
    return _rtdb.getMap(
      FirebasePaths.attendanceDate(session.companyId, session.uid, dateKey),
    );
  }

  Future<void> submitCorrectionRequest({
    required AppSession session,
    required String dateKey,
    required String correctionType,
    required String reason,
    required String requestedCheckInTime,
    required String requestedCheckOutTime,
    File? attachmentFile,
    String attachmentName = '',
    Map<String, dynamic>? oldAttendance,
  }) async {
    final normalizedDate = dateKey.trim();
    final normalizedType = correctionType.trim().toLowerCase();
    final normalizedReason = reason.trim();
    final normalizedCheckIn = requestedCheckInTime.trim();
    final normalizedCheckOut = requestedCheckOutTime.trim();

    if (normalizedDate.isEmpty) {
      throw Exception('Tanggal koreksi wajib diisi.');
    }
    if (!_isValidType(normalizedType)) {
      throw Exception('Tipe koreksi tidak valid.');
    }
    if (normalizedReason.isEmpty) {
      throw Exception('Alasan koreksi wajib diisi.');
    }
    if (_needsCheckIn(normalizedType) && normalizedCheckIn.isEmpty) {
      throw Exception('Jam Clock In yang diajukan wajib diisi.');
    }
    if (_needsCheckOut(normalizedType) && normalizedCheckOut.isEmpty) {
      throw Exception('Jam Clock Out yang diajukan wajib diisi.');
    }

    await _ensureNoActiveRequest(
      session: session,
      dateKey: normalizedDate,
      correctionType: normalizedType,
    );

    final ts = DateTime.now().millisecondsSinceEpoch;
    final correctionId = 'correction_$ts';
    final attendance = oldAttendance ??
        await getAttendanceMap(session: session, dateKey: normalizedDate) ??
        <String, dynamic>{};

    String attachmentUrl = '';
    String attachmentPath = '';
    String savedAttachmentName = '';
    if (attachmentFile != null) {
      savedAttachmentName =
          attachmentName.isEmpty ? 'correction_$ts.jpg' : attachmentName;
      attachmentPath = FirebasePaths.attendanceCorrectionAttachment(
        session.companyId,
        session.uid,
        correctionId,
        savedAttachmentName,
      );
      attachmentUrl =
          await _storage.uploadFile(path: attachmentPath, file: attachmentFile);
    }

    final request = AttendanceCorrectionRequest(
      correctionId: correctionId,
      companyId: session.companyId,
      uid: session.uid,
      userName: session.displayName,
      nip: session.nip,
      date: normalizedDate,
      correctionType: normalizedType,
      requestedCheckInTime: normalizedCheckIn,
      requestedCheckOutTime: normalizedCheckOut,
      reason: normalizedReason,
      attachmentUrl: attachmentUrl,
      attachmentPath: attachmentPath,
      attachmentName: savedAttachmentName,
      oldAttendance: attendance,
      source: 'mobile_app',
      status: 'pending',
      adminUid: '',
      adminName: '',
      adminNote: '',
      validatedAt: 0,
      approvedBy: '',
      approvedByName: '',
      approvedAt: 0,
      rejectedBy: '',
      rejectedByName: '',
      rejectedAt: 0,
      officeId: session.officeId,
      officeName: session.officeName,
      departmentId: session.departmentId,
      departmentName: session.departmentName,
      subDepartmentId: session.subDepartmentId,
      subDepartmentName: session.subDepartmentName,
      groupId: session.groupId,
      groupName: session.groupName,
      createdAt: ts,
      updatedAt: ts,
    );

    await _rtdb.set(
      FirebasePaths.attendanceCorrection(session.companyId, correctionId),
      request.toMap(),
    );
  }

  Future<void> _ensureNoActiveRequest({
    required AppSession session,
    required String dateKey,
    required String correctionType,
  }) async {
    final root = await _rtdb.getMap(
          FirebasePaths.attendanceCorrections(session.companyId),
        ) ??
        <String, dynamic>{};

    for (final entry in root.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final row = asMap(value);
      if (asString(row['uid']) != session.uid) continue;
      final rowDate = asString(row['date'], asString(row['tanggal']));
      if (rowDate != dateKey) continue;
      final rowType = asString(row['correction_type']).toLowerCase();
      if (rowType.isEmpty) continue;
      if (!_isActiveStatus(asString(row['status']))) continue;
      if (!_isOverlap(correctionType, rowType)) continue;
      throw Exception(
          'Sudah ada pengajuan koreksi aktif yang tumpang tindih untuk tanggal tersebut.');
    }
  }

  bool _isValidType(String type) {
    return type == 'masuk' || type == 'pulang' || type == 'masuk_pulang';
  }

  bool _isActiveStatus(String status) {
    final normalized = RequestStatusItem.normalizeStatus(status);
    final raw = status.trim().toLowerCase();
    return normalized == 'pending' ||
        normalized == 'approved' ||
        raw == 'pending_admin' ||
        raw == 'processing' ||
        raw == 'validated';
  }

  bool _isOverlap(String currentType, String existingType) {
    if (currentType == existingType) return true;
    if (currentType == 'masuk_pulang') {
      return existingType == 'masuk' ||
          existingType == 'pulang' ||
          existingType == 'masuk_pulang';
    }
    if (currentType == 'masuk') {
      return existingType == 'masuk' || existingType == 'masuk_pulang';
    }
    if (currentType == 'pulang') {
      return existingType == 'pulang' || existingType == 'masuk_pulang';
    }
    return false;
  }

  bool _needsCheckIn(String type) {
    return type == 'masuk' || type == 'masuk_pulang';
  }

  bool _needsCheckOut(String type) {
    return type == 'pulang' || type == 'masuk_pulang';
  }
}
