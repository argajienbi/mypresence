import 'package:firebase_database/firebase_database.dart';

class RtdbService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  DatabaseReference ref(String path) => _db.ref(path);

  Future<Map<String, dynamic>?> getMap(String path) async {
    final snap = await ref(path).get();
    if (!snap.exists || snap.value == null) return null;
    final value = snap.value;
    if (value is Map) return value.map((key, val) => MapEntry(key.toString(), val));
    return null;
  }

  Future<List<MapEntry<String, dynamic>>> getMapEntries(String path) async {
    final map = await getMap(path) ?? <String, dynamic>{};
    return map.entries.toList();
  }

  Stream<DatabaseEvent> onValue(String path) => ref(path).onValue;
  Future<void> set(String path, Map<String, dynamic> data) => ref(path).set(data);
  Future<void> update(String path, Map<String, dynamic> data) => ref(path).update(data);
  Future<String> pushKey(String path) async => ref(path).push().key ?? DateTime.now().millisecondsSinceEpoch.toString();
}
