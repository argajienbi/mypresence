import 'dart:io';

import '../core/firebase_paths.dart';
import '../core/models/app_session.dart';
import '../core/models/presence_submission_result.dart';
import '../core/utils.dart';
import 'location_service.dart';
import 'rtdb_service.dart';
import 'photo_quality_service.dart';
import 'schedule_service.dart';
import 'storage_service.dart';

class ParsedEmployeeQr {
  final String companyId;
  final String uid;
  final String nip;
  final String token;
  ParsedEmployeeQr(
      {required this.companyId,
      required this.uid,
      required this.nip,
      required this.token});
}

class QrService {
  final RtdbService _rtdb = RtdbService();
  final LocationService _location = LocationService();
  final ScheduleService _schedule = ScheduleService();
  final StorageService _storage = StorageService();
  final PhotoQualityService _photoQuality = PhotoQualityService();

  String employeeQrPayload(AppSession session, String qrToken) =>
      'MYPRESENCE_EMPLOYEE_QR|${session.companyId}|${session.uid}|${session.nip}|$qrToken';

  ParsedEmployeeQr parse(String raw) {
    final parts = raw.split('|');
    const legacyPrefix = 'MYPRESNSI_EMPLOYEE_QR';
    const currentPrefix = 'MYPRESENCE_EMPLOYEE_QR';
    if (parts.length != 5 ||
        (parts[0] != legacyPrefix && parts[0] != currentPrefix)) {
      throw Exception('Format QR tidak valid.');
    }
    return ParsedEmployeeQr(
        companyId: parts[1], uid: parts[2], nip: parts[3], token: parts[4]);
  }

  Future<String> ensureQrToken(AppSession session) async {
    final path = FirebasePaths.companyUser(session.companyId, session.uid);
    final map = await _rtdb.getMap(path) ?? {};
    final existing = asString(map['qr_token']);
    if (existing.isNotEmpty && map['qr_active'] == true) return existing;
    final token =
        'QR_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    await _rtdb.update(path, {
      'qr_token': token,
      'qr_active': true,
      'qr_updated_at': DateTime.now().millisecondsSinceEpoch
    });
    return token;
  }

  Future<Map<String, dynamic>> validateTargetQr(
      AppSession helperSession, String raw) async {
    final qr = parse(raw);
    if (qr.companyId != helperSession.companyId) {
      throw Exception('QR berbeda perusahaan.');
    }
    if (qr.uid == helperSession.uid) {
      throw Exception('Tidak bisa scan QR milik sendiri.');
    }
    final target =
        await _rtdb.getMap(FirebasePaths.companyUser(qr.companyId, qr.uid));
    if (target == null) throw Exception('Target QR tidak ditemukan.');
    if (asString(target['status_akun']) != 'active') {
      throw Exception('Target belum aktif.');
    }
    final targetOfficeId = asString(target['office_id']);
    if (targetOfficeId.isEmpty) {
      throw Exception('Data kantor target belum lengkap. Hubungi admin.');
    }
    final helperOfficeId = asString(helperSession.officeId);
    if (helperOfficeId.isEmpty) {
      throw Exception('Data kantor akun Anda belum lengkap. Hubungi admin.');
    }
    if (targetOfficeId != helperOfficeId) {
      throw Exception('QR hanya bisa digunakan oleh karyawan di kantor yang sama.');
    }
    if (asString(target['qr_token']) != qr.token ||
        target['qr_active'] != true) {
      throw Exception('QR token tidak valid/tidak aktif.');
    }
    target['uid'] = asString(target['uid'], qr.uid);
    return target;
  }

  Future<PresenceSubmissionResult> createProxyRequest({
    required AppSession helperSession,
    required Map<String, dynamic> target,
    required String actionType,
    required File photoFile,
    PhotoQualityCheckResult? photoQuality,
  }) async {
    if (actionType != 'masuk' && actionType != 'pulang') {
      throw Exception('Jenis aksi tidak valid.');
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now();
    final dateKey = AppDate.dateKey(now);
    final time = AppDate.time(now);
    final requestId = 'qr_req_$ts';
    final targetUid = asString(target['uid']);
    if (targetUid.isEmpty) {
      throw Exception('Target QR tidak valid.');
    }

    final uploadPhotoFile = await _photoQuality.prepareForUpload(photoFile);
    final photoQualityResult = await _photoQuality.validate(uploadPhotoFile);
    if (!photoQualityResult.isValid) {
      throw Exception(photoQualityResult.message);
    }

    DailySchedule? helperSchedule;
    try {
      helperSchedule = await _schedule.resolveToday(helperSession, now: now);
    } catch (_) {
      helperSchedule = null;
    }

    final loc = await _location.currentLocation();
    final distance = _location.distanceMeter(
      fromLat: loc.latitude,
      fromLng: loc.longitude,
      toLat: helperSession.officeLatitude,
      toLng: helperSession.officeLongitude,
    );
    final geofenceStatus =
        distance <= helperSession.officeRadiusMeter ? 'inside' : 'outside';
    if (geofenceStatus != 'inside') {
      throw Exception(
          'Anda berada di luar radius kantor (${distance.toStringAsFixed(0)} m dari kantor).');
    }
    final locationAssessment = _location.assessLocation(loc);
    final photoPath = FirebasePaths.qrAttendancePhoto(
        helperSession.companyId, targetUid, dateKey, actionType, ts);
    final photoUrl =
        await _storage.uploadFile(path: photoPath, file: uploadPhotoFile);

    final targetOfficeId = asString(target['office_id'], helperSession.officeId);
    final targetOfficeName = asString(target['office_name'], helperSession.officeName);
    final targetDepartmentId = asString(target['department_id']);
    final targetDepartmentName = asString(target['department_name']);
    final targetSubDepartmentId = asString(target['sub_department_id']);
    final targetSubDepartmentName = asString(target['sub_department_name']);
    final targetGroupId = asString(target['group_id']);
    final targetGroupName = asString(target['group_name']);

    final payload = {
      'request_id': requestId,
      'company_id': helperSession.companyId,
      'target_uid': targetUid,
      'target_name': asString(target['nama_lengkap']),
      'target_nip': asString(target['nip']),
      'target_position': asString(target['position']),
      'target_office_id': targetOfficeId,
      'target_office_name': targetOfficeName,
      'target_department_id': targetDepartmentId,
      'target_department_name': targetDepartmentName,
      'target_sub_department_id': targetSubDepartmentId,
      'target_sub_department_name': targetSubDepartmentName,
      'target_group_id': targetGroupId,
      'target_group_name': targetGroupName,
      'helper_uid': helperSession.uid,
      'helper_name': helperSession.displayName,
      'helper_nip': helperSession.nip,
      'helper_office_id': helperSession.officeId,
      'helper_office_name': helperSession.officeName,
      'helper_department_id': helperSession.departmentId,
      'helper_department_name': helperSession.departmentName,
      'helper_sub_department_id': helperSession.subDepartmentId,
      'helper_sub_department_name': helperSession.subDepartmentName,
      'helper_group_id': helperSession.groupId,
      'helper_group_name': helperSession.groupName,
      'date': dateKey,
      'tanggal': dateKey,
      'time': time,
      'waktu': time,
      'timestamp': ts,
      'action_type': actionType,
      'method': 'qr',
      'source': 'mobile_app',
      'status': 'pending',
      'attendance_status': 'pending_admin',
      'validation_status': 'pending_admin',
      'schedule_source': 'pending_admin_resolution',
      'schedule_ready': false,
      'assignment_id': '',
      'assignment_start_date': '',
      'assignment_end_date': '',
      'shift_id': '',
      'shift_name': '',
      'timetable_id': '',
      'timetable_name': '',
      'work_start': '',
      'work_end': '',
      'check_in_start': '',
      'check_in_end': '',
      'check_out_start': '',
      'check_out_end': '',
      'late_tolerance_minute': 0,
      'early_out_tolerance_minute': 0,
      'crosses_midnight': false,
      'overtime_flag': false,
      'overtime_schedule_id': '',
      'is_holiday_work': false,
      'helper_schedule_source': helperSchedule?.source ?? '',
      'helper_schedule_ready': helperSchedule?.scheduleReady ?? false,
      'helper_assignment_id': helperSchedule?.assignmentId ?? '',
      'helper_assignment_start_date': helperSchedule?.assignmentStartDate ?? '',
      'helper_assignment_end_date': helperSchedule?.assignmentEndDate ?? '',
      'helper_shift_id': helperSchedule?.shiftId ?? '',
      'helper_shift_name': helperSchedule?.shiftName ?? '',
      'helper_timetable_id': helperSchedule?.timetableId ?? '',
      'helper_timetable_name': helperSchedule?.timetableName ?? '',
      'photo_url': photoUrl,
      'photo_path': photoPath,
      'photo_quality_status': photoQualityResult.status,
      'photo_quality_warning': photoQualityResult.hasWarning ? photoQualityResult.message : '',
      'photo_file_size': photoQualityResult.fileSize,
      'photo_width': photoQualityResult.width,
      'photo_height': photoQualityResult.height,
      'latitude': loc.latitude,
      'longitude': loc.longitude,
      'accuracy': loc.accuracy,
      'location_accuracy': loc.accuracy,
      'office_latitude': helperSession.officeLatitude,
      'office_longitude': helperSession.officeLongitude,
      'distance_meter': distance,
      'radius_meter': helperSession.officeRadiusMeter,
      'geofence_status': geofenceStatus,
      'mock_location_detected': loc.isMocked,
      'location_mock_detected': loc.isMocked,
      'location_mock_warning': locationAssessment.mockWarningMessage,
      'location_accuracy_warning': locationAssessment.accuracyWarning,
      'location_risk_level': locationAssessment.riskLevel,
      'location_warning': locationAssessment.warningMessage,
      'location_provider': 'geolocator',
      'office_id': helperSession.officeId,
      'office_name': helperSession.officeName,
      'department_id': targetDepartmentId,
      'department_name': targetDepartmentName,
      'sub_department_id': targetSubDepartmentId,
      'sub_department_name': targetSubDepartmentName,
      'group_id': targetGroupId,
      'group_name': targetGroupName,
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
      'created_by_uid': helperSession.uid,
      'created_by_name': helperSession.displayName,
      'created_by_qr': true,
      'note': 'Presensi dibuat melalui QR oleh ${helperSession.displayName}',
      'created_at': ts,
      'updated_at': ts,
    };
    await _rtdb.set(
        FirebasePaths.qrRequest(helperSession.companyId, requestId), payload);

    return PresenceSubmissionResult(
      photoQualityStatus: photoQualityResult.status,
      photoQualityWarning: '',
      photoFileSize: photoQualityResult.fileSize,
      photoWidth: photoQualityResult.width,
      photoHeight: photoQualityResult.height,
      locationRiskLevel: locationAssessment.riskLevel,
      locationWarning: locationAssessment.warningMessage,
      locationAccuracy: loc.accuracy,
      distanceMeter: distance,
      locationMockDetected: loc.isMocked,
    );
  }
}
