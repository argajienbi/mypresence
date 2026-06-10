import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Future<String> uploadFile({required String path, required File file}) async {
    final ref = _storage.ref(path);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> downloadUrl(String path) async {
    try {
      if (path.trim().isEmpty) return '';
      if (path.startsWith('http://') || path.startsWith('https://')) return path;
      return await _storage.ref(path).getDownloadURL();
    } catch (_) {
      return '';
    }
  }
}
