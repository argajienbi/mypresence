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
  if (raw.toLowerCase().contains('permission')) return 'Akses data ditolak. Cek akun atau hubungi admin.';
  if (raw.toLowerCase().contains('firebase')) return 'Terjadi kendala layanan. Coba lagi.';
  if (raw.toLowerCase().contains('credential')) return 'Email atau password tidak sesuai.';
  return raw.isEmpty ? 'Terjadi kendala. Coba lagi.' : raw;
}
