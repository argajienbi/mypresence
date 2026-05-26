import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../core/firebase_paths.dart';
import '../core/models/app_session.dart';
import 'rtdb_service.dart';
import 'storage_service.dart';

class ProfilePhotoResult {
  final String photoUrl;
  final String photoPath;

  const ProfilePhotoResult({required this.photoUrl, required this.photoPath});
}

class ProfileService {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storage = StorageService();
  final RtdbService _rtdb = RtdbService();

  Future<ProfilePhotoResult?> pickUploadAndSavePhoto({
    required AppSession session,
    required ImageSource source,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 82,
    );
    if (picked == null) return null;

    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = FirebasePaths.profilePhoto(session.companyId, session.uid, ts);
    final url = await _storage.uploadFile(path: path, file: File(picked.path));
    final update = {
      'photo_url': url,
      'photo_path': path,
      'updated_at': ts,
    };

    await _rtdb.update(FirebasePaths.user(session.uid), update);
    await _rtdb.update(FirebasePaths.companyUser(session.companyId, session.uid), update);
    return ProfilePhotoResult(photoUrl: url, photoPath: path);
  }

  Future<void> updateBasicProfile({
    required AppSession session,
    required String namaLengkap,
    required String noHp,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final update = {
      'nama_lengkap': namaLengkap.trim(),
      'no_hp': noHp.trim(),
      'updated_at': ts,
    };
    await _rtdb.update(FirebasePaths.user(session.uid), update);
    await _rtdb.update(FirebasePaths.companyUser(session.companyId, session.uid), update);
  }
}
