import 'package:firebase_database/firebase_database.dart';

import '../core/models/announcement.dart';
import '../core/models/app_session.dart';

class AnnouncementService {
  AnnouncementService();

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Stream<List<Announcement>> watchAnnouncements(AppSession session) {
    return _database
        .ref('companies/${session.companyId}/announcements')
        .onValue
        .map((event) {
      final value = event.snapshot.value;

      if (value is! Map) {
        return <Announcement>[];
      }

      final items = <Announcement>[];

      for (final entry in value.entries) {
        final rawValue = entry.value;

        if (rawValue is! Map) continue;

        final id = entry.key.toString();
        final data = Map<String, dynamic>.from(
          rawValue.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        );

        final item = Announcement.fromMap(
          id,
          data,
          fallbackCompanyId: session.companyId,
        );

        if (!item.active || item.status != 'published') continue;

        if (_isTargetedToSession(item, session)) {
          items.add(item);
        }
      }

      items.sort((a, b) {
        final left = b.publishedAt != 0 ? b.publishedAt : b.createdAt;
        final right = a.publishedAt != 0 ? a.publishedAt : a.createdAt;
        return left.compareTo(right);
      });

      return items;
    });
  }

  bool _isTargetedToSession(Announcement item, AppSession session) {
    if (item.targetType == 'all') return true;

    if (item.targetType == 'user') {
      return item.targetIds.contains(session.uid);
    }

    if (item.targetType == 'office') {
      return item.targetIds.contains(session.officeId);
    }

    if (item.targetType == 'area') {
      return item.targetIds.contains(session.areaId);
    }

    if (item.targetType == 'department') {
      return item.targetIds.contains(session.departmentId);
    }

    if (item.targetType == 'sub_department') {
      return item.targetIds.contains(session.subDepartmentId);
    }

    if (item.targetType == 'group') {
      return item.targetIds.contains(session.groupId);
    }

    return false;
  }
}