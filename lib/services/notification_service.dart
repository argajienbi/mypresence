import '../core/firebase_paths.dart';
import '../core/utils.dart';
import 'rtdb_service.dart';

class NotificationService {
  final RtdbService _rtdb = RtdbService();

  Future<void> createNotification({
    required String uid,
    required String title,
    required String body,
    required String type,
    String companyId = '',
    String relatedId = '',
    String refType = '',
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final id = 'notif_$ts';
    await _rtdb.set(FirebasePaths.notification(uid, id), {
      'notification_id': id,
      'uid': uid,
      'company_id': companyId,
      'title': title,
      'body': body,
      'message': body,
      'type': type,
      'related_id': relatedId,
      'ref_id': relatedId,
      'ref_type': refType,
      'read': false,
      'created_at': ts,
    });
  }

  Future<List<Map<String, dynamic>>> listUserNotifications(String uid) async {
    final map = await _rtdb.getMap(FirebasePaths.notifications(uid)) ?? <String, dynamic>{};
    final list = map.entries.map((e) {
      final item = asMap(e.value);
      item['id'] = e.key;
      return item;
    }).toList();
    list.sort((a, b) => asInt(b['created_at']).compareTo(asInt(a['created_at'])));
    return list;
  }
}
