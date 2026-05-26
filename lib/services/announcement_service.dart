import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_paths.dart';
import '../core/models/announcement.dart';
import '../core/models/app_session.dart';

class AnnouncementService {
  AnnouncementService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Announcement>> watchAnnouncements(AppSession session) {
    return _firestore
        .collection(FirestorePaths.announcements(session.companyId))
        .orderBy('published_at', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map((doc) {
        return Announcement.fromMap(
          doc.id,
          doc.data(),
          fallbackCompanyId: session.companyId,
        );
      }).where((item) {
        if (!item.active || item.status != 'published') return false;
        if (item.targetType == 'all') return true;
        if (item.targetType == 'user') return item.targetIds.contains(session.uid);
        if (item.targetType == 'office') return item.targetIds.contains(session.officeId);
        if (item.targetType == 'department') return item.targetIds.contains(session.departmentId);
        if (item.targetType == 'sub_department') return item.targetIds.contains(session.subDepartmentId);
        if (item.targetType == 'group') return item.targetIds.contains(session.groupId);
        return false;
      }).toList();
      return items;
    });
  }
}
