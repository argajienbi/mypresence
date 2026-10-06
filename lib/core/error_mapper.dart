import 'package:firebase_auth/firebase_auth.dart';

String friendlyError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email atau password tidak sesuai.';
      case 'invalid-email':
        return 'Format email belum benar.';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan. Hubungi admin.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba beberapa saat lagi.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'weak-password':
        return 'Password terlalu lemah.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah.';
      default:
        return 'Terjadi kendala autentikasi. Coba lagi.';
    }
  }

  final raw = error.toString().replaceFirst('Exception: ', '');
  final lower = raw.toLowerCase();
  if (lower.contains('cameraexception') ||
      lower.contains('illegalargumentexception') ||
      lower.contains('surface combination') ||
      lower.contains('use cases') ||
      lower.contains('camera device') ||
      lower.contains('camera is closed') ||
      lower.contains('already in use')) {
    if (lower.contains('surface combination') ||
        lower.contains('use cases') ||
        lower.contains('illegalargumentexception') ||
        lower.contains('already in use')) {
      return 'Kamera sedang memproses. Tunggu sebentar lalu coba lagi.';
    }
    return 'Kamera belum siap. Jangan tekan tombol berulang.';
  }
  if (lower.contains('permission')) return 'Akses data ditolak. Cek akun atau hubungi admin.';
  if (lower.contains('firebase')) return 'Terjadi kendala layanan. Coba lagi.';
  // Cek error upload/penyimpanan DULU: pesan error R2 mengandung kata
  // "Credential" (mis. "Credential access key has length 53") dan tidak boleh
  // disalahartikan sebagai error login.
  if (lower.contains('cloudflare') || lower.contains('gagal upload')) {
    return 'Gagal mengunggah foto ke penyimpanan. Coba lagi.';
  }
  if (lower.contains('credential')) return 'Email atau password tidak sesuai.';
  return raw.isEmpty ? 'Terjadi kendala. Coba lagi.' : raw;
}
