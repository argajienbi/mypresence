import '../core/firebase_paths.dart';
import '../core/models/app_session.dart';
import 'rtdb_service.dart';

class LeaveService {
  final RtdbService _rtdb = RtdbService();

  Future<void> submitLeave({required AppSession session, required String type, required String dateStart, required String dateEnd, required String reason}) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final requestId = 'leave_$ts';
    final payload = {
      'request_id': requestId,
      'company_id': session.companyId,
      'uid': session.uid,
      'user_name': session.displayName,
      'nip': session.nip,
      'type': type,
      'date_start': dateStart,
      'date_end': dateEnd,
      'reason': reason,
      'attachment_url': '',
      'attachment_path': '',
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

  Future<List<Map<String, dynamic>>> getMonthlyRequests({required AppSession session, required DateTime month}) async {
    final root = await _rtdb.getMap(FirebasePaths.leaveRequests(session.companyId)) ?? <String, dynamic>{};
    final rows = <Map<String, dynamic>>[];
    for (final entry in root.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final map = value.map((k, v) => MapEntry(k.toString(), v));
      if ((map['uid'] ?? '').toString() != session.uid) continue;
      final start = DateTime.tryParse((map['date_start'] ?? map['date'] ?? '').toString());
      if (start == null || start.year != month.year || start.month != month.month) continue;
      rows.add({'request_id': entry.key, ...map});
    }
    rows.sort((a, b) => (b['date_start'] ?? b['date'] ?? '').toString().compareTo((a['date_start'] ?? a['date'] ?? '').toString()));
    return rows;
  }

}
