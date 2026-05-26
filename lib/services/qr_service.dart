import '../core/firebase_paths.dart';
import '../core/models/app_session.dart';
import '../core/utils.dart';
import 'location_service.dart';
import 'rtdb_service.dart';
import 'schedule_service.dart';

class ParsedEmployeeQr {
  final String companyId;
  final String uid;
  final String nip;
  final String token;
  ParsedEmployeeQr({required this.companyId, required this.uid, required this.nip, required this.token});
}

class QrService {
  final RtdbService _rtdb = RtdbService();
  final LocationService _location = LocationService();
  final ScheduleService _schedule = ScheduleService();

  String employeeQrPayload(AppSession session, String qrToken) => 'MYPRESNSI_EMPLOYEE_QR|${session.companyId}|${session.uid}|${session.nip}|$qrToken';

  ParsedEmployeeQr parse(String raw) {
    final parts = raw.split('|');
    if (parts.length != 5 || parts[0] != 'MYPRESNSI_EMPLOYEE_QR') throw Exception('Format QR tidak valid.');
    return ParsedEmployeeQr(companyId: parts[1], uid: parts[2], nip: parts[3], token: parts[4]);
  }

  Future<String> ensureQrToken(AppSession session) async {
    final path = FirebasePaths.companyUser(session.companyId, session.uid);
    final map = await _rtdb.getMap(path) ?? {};
    final existing = asString(map['qr_token']);
    if (existing.isNotEmpty && map['qr_active'] == true) return existing;
    final token = 'QR_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    await _rtdb.update(path, {'qr_token': token, 'qr_active': true, 'qr_updated_at': DateTime.now().millisecondsSinceEpoch});
    return token;
  }

  Future<Map<String, dynamic>> validateTargetQr(AppSession helperSession, String raw) async {
    final qr = parse(raw);
    if (qr.companyId != helperSession.companyId) throw Exception('QR berbeda perusahaan.');
    if (qr.uid == helperSession.uid) throw Exception('Tidak bisa scan QR milik sendiri.');
    final target = await _rtdb.getMap(FirebasePaths.companyUser(qr.companyId, qr.uid));
    if (target == null) throw Exception('Target QR tidak ditemukan.');
    if (asString(target['status_akun']) != 'active') throw Exception('Target belum aktif.');
    if (asString(target['qr_token']) != qr.token || target['qr_active'] != true) throw Exception('QR token tidak valid/tidak aktif.');
    target['uid'] = asString(target['uid'], qr.uid);
    return target;
  }

  Future<void> createProxyRequest({required AppSession helperSession, required Map<String, dynamic> target, required String actionType}) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.now();
    final dateKey = AppDate.dateKey(now);
    final time = AppDate.time(now);
    final requestId = 'qr_req_$ts';

    double latitude = 0;
    double longitude = 0;
    double accuracy = 0;
    double distance = 0;
    String geofenceStatus = 'unknown';

    try {
      final loc = await _location.currentLocation();
      latitude = loc.latitude;
      longitude = loc.longitude;
      accuracy = loc.accuracy;
      distance = _location.distanceMeter(
        fromLat: loc.latitude,
        fromLng: loc.longitude,
        toLat: helperSession.officeLatitude,
        toLng: helperSession.officeLongitude,
      );
      geofenceStatus = distance <= helperSession.officeRadiusMeter ? 'inside' : 'outside';
      if (geofenceStatus != 'inside') {
        throw Exception('Anda berada di luar radius kantor (${distance.toStringAsFixed(0)} m dari kantor).');
      }
    } catch (_) {
      rethrow;
    }

    final schedule = await _schedule.resolveToday(helperSession, now: now);

    final payload = {
      'request_id': requestId,
      'company_id': helperSession.companyId,
      'target_uid': asString(target['uid']),
      'target_name': asString(target['nama_lengkap']),
      'target_nip': asString(target['nip']),
      'target_position': asString(target['position']),
      'target_office_id': asString(target['office_id']),
      'target_department_id': asString(target['department_id']),
      'target_sub_department_id': asString(target['sub_department_id']),
      'target_group_id': asString(target['group_id']),
      'helper_uid': helperSession.uid,
      'helper_name': helperSession.displayName,
      'helper_nip': helperSession.nip,
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
      'photo_url': '',
      'photo_path': '',
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'office_latitude': helperSession.officeLatitude,
      'office_longitude': helperSession.officeLongitude,
      'distance_meter': distance,
      'radius_meter': helperSession.officeRadiusMeter,
      'geofence_status': geofenceStatus,
      'office_id': helperSession.officeId,
      'office_name': helperSession.officeName,
      'department_id': asString(target['department_id']),
      'sub_department_id': asString(target['sub_department_id']),
      'group_id': asString(target['group_id']),
      ...schedule.toAttendancePayload(),
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
      'note': 'Presensi dibuat melalui QR oleh ${helperSession.displayName}',
      'created_at': ts,
      'updated_at': ts,
    };
    await _rtdb.set(FirebasePaths.qrRequest(helperSession.companyId, requestId), payload);
  }
}
