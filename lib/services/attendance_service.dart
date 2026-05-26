import 'dart:io';

import '../core/firebase_paths.dart';
import '../core/models/app_session.dart';
import '../core/utils.dart';
import 'location_service.dart';
import 'rtdb_service.dart';
import 'storage_service.dart';
import 'schedule_service.dart';
import '../models/attendance_record.dart';

class AttendanceService {
  final RtdbService _rtdb = RtdbService();
  final StorageService _storage = StorageService();
  final LocationService _location = LocationService();
  final ScheduleService _schedule = ScheduleService();

  Future<void> submitSelfieAttendance({required AppSession session, required String actionType, required File photoFile}) async {
    final now = DateTime.now();
    final date = AppDate.dateKey(now);
    final time = AppDate.time(now);
    final ts = now.millisecondsSinceEpoch;

    final schedule = await _schedule.resolveToday(session, now: now);
    final window = _schedule.validateAction(schedule: schedule, actionType: actionType, now: now);
    if (!window.allowed) {
      throw Exception(window.message);
    }

    final loc = await _location.currentLocation();
    final distance = _location.distanceMeter(fromLat: loc.latitude, fromLng: loc.longitude, toLat: session.officeLatitude, toLng: session.officeLongitude);
    final inside = distance <= session.officeRadiusMeter;
    if (!inside) {
      throw Exception('Anda berada di luar radius kantor (${distance.toStringAsFixed(0)} m dari kantor).');
    }

    final photoPath = FirebasePaths.attendancePhoto(session.companyId, session.uid, date, actionType, ts);
    final photoUrl = await _storage.uploadFile(path: photoPath, file: photoFile);

    final payload = <String, dynamic>{
      'record_id': '${session.companyId}_${session.uid}_${date}_$actionType',
      'company_id': session.companyId,
      'uid': session.uid,
      'user_name': session.displayName,
      'nip': session.nip,
      'date': date,
      'tanggal': date,
      'time': time,
      'waktu': time,
      'timestamp': ts,
      'action_type': actionType,
      'method': 'selfie',
      'source': 'mobile_app',
      'status': 'approved',
      'attendance_status': window.status,
      'validation_message': window.message,
      'early_out': window.earlyOut,
      'photo_url': photoUrl,
      'photo_path': photoPath,
      'latitude': loc.latitude,
      'longitude': loc.longitude,
      'accuracy': loc.accuracy,
      'distance_meter': distance,
      'radius_meter': session.officeRadiusMeter,
      'office_latitude': session.officeLatitude,
      'office_longitude': session.officeLongitude,
      'geofence_status': 'inside',
      'office_id': session.officeId,
      'office_name': session.officeName,
      'department_id': session.departmentId,
      'department_name': session.departmentName,
      'sub_department_id': session.subDepartmentId,
      'sub_department_name': session.subDepartmentName,
      'group_id': session.groupId,
      'group_name': session.groupName,
      ...schedule.toAttendancePayload(),
      'created_by_uid': session.uid,
      'created_by_name': session.displayName,
      'created_by_qr': false,
      'validation_status': 'approved',
      'proxy_request_id': '',
      'created_at': ts,
      'updated_at': ts,
    };

    await _rtdb.set(FirebasePaths.attendanceRecord(session.companyId, session.uid, date, actionType), payload);
  }

  Future<Map<String, dynamic>?> todayAttendance(AppSession session) => _rtdb.getMap(FirebasePaths.attendanceDate(session.companyId, session.uid, AppDate.dateKey()));
  Future<Map<String, dynamic>?> attendanceAll(AppSession session) => _rtdb.getMap(FirebasePaths.attendanceUser(session.companyId, session.uid));

  Future<TodayAttendance> getTodayAttendance(AppSession session) async {
    final map = await todayAttendance(session) ?? <String, dynamic>{};
    final masukMap = map['masuk'] is Map ? Map<String, dynamic>.from((map['masuk'] as Map).map((k, v) => MapEntry(k.toString(), v))) : null;
    final pulangMap = map['pulang'] is Map ? Map<String, dynamic>.from((map['pulang'] as Map).map((k, v) => MapEntry(k.toString(), v))) : null;
    return TodayAttendance(
      masuk: masukMap == null ? null : AttendanceRecord.fromMap('masuk', masukMap),
      pulang: pulangMap == null ? null : AttendanceRecord.fromMap('pulang', pulangMap),
    );
  }

  Future<List<Map<String, dynamic>>> getMonthlyHistory({required AppSession session, required DateTime month}) async {
    final all = await attendanceAll(session) ?? <String, dynamic>{};
    final rows = <Map<String, dynamic>>[];
    for (final entry in all.entries) {
      final date = entry.key;
      final value = entry.value;
      if (value is! Map) continue;
      final parsed = DateTime.tryParse(date);
      if (parsed == null || parsed.year != month.year || parsed.month != month.month) continue;
      rows.add({
        'date': date,
        ...value.map((k, v) => MapEntry(k.toString(), v)),
      });
    }
    rows.sort((a, b) => (b['date'] ?? '').toString().compareTo((a['date'] ?? '').toString()));
    return rows;
  }

}
