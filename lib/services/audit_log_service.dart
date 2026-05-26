import '../core/firebase_paths.dart';
import '../core/models/app_session.dart';
import 'rtdb_service.dart';

class AuditLogService {
  final RtdbService _rtdb = RtdbService();

  Future<void> write({
    required AppSession session,
    required String action,
    required String targetPath,
    String details = '',
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final id = 'log_$ts';
    await _rtdb.set(FirebasePaths.auditLog(session.companyId, id), {
      'log_id': id,
      'company_id': session.companyId,
      'actor_uid': session.uid,
      'actor_name': session.displayName,
      'user_uid': session.uid,
      'user_name': session.displayName,
      'action': action,
      'details': details,
      'target_path': targetPath,
      'source': 'mobile_app',
      'created_at': ts,
    });
  }
}
