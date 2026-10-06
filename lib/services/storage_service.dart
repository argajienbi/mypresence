import 'dart:convert';
import 'dart:io';

import '../core/constants/r2_config.dart';
import '../core/utils/r2_signer.dart';

class StorageService {
  /// Upload file ke Cloudflare R2 bucket menggunakan S3-compatible PutObject API.
  /// Mengembalikan string public URL file yang berhasil diupload.
  Future<String> uploadFile({required String path, required File file}) async {
    if (!await file.exists()) {
      throw Exception('File yang akan diupload tidak ditemukan: ${file.path}');
    }

    final endpoint = R2Config.endpoint.trim().replaceAll(RegExp(r'/+$'), '');
    final bucket = R2Config.bucket.trim();
    final accessKeyId = R2Config.accessKeyId.trim();
    final secretAccessKey = R2Config.secretAccessKey.trim();

    if (_isPlaceholder(endpoint) ||
        _isPlaceholder(bucket) ||
        _isPlaceholder(accessKeyId) ||
        _isPlaceholder(secretAccessKey)) {
      throw Exception(
        'Kredensial Cloudflare R2 belum dikonfigurasi. '
        'Silakan isi nilai kredensial di lib/core/constants/r2_config.dart.',
      );
    }

    final key = path.startsWith('/') ? path.substring(1) : path;
    final fileBytes = await file.readAsBytes();
    final contentType = _getContentType(key);
    final targetUri = Uri.parse('$endpoint/$bucket/$key');
    final now = DateTime.now().toUtc();
    final amzDate = R2Signer.formatAmzDate(now);
    final payloadHash = R2Crypto.hex(R2Crypto.sha256(fileBytes));

    final authHeader = R2Signer.createAuthorizationHeader(
      method: 'PUT',
      uri: targetUri,
      payload: fileBytes,
      contentType: contentType,
      accessKeyId: accessKeyId,
      secretAccessKey: secretAccessKey,
      timestamp: now,
    );

    final client = HttpClient();
    try {
      final request = await client.putUrl(targetUri);
      request.headers.set('host', targetUri.host);
      request.headers.set('x-amz-date', amzDate);
      request.headers.set('x-amz-content-sha256', payloadHash);
      request.headers.set(HttpHeaders.contentTypeHeader, contentType);
      request.headers.set(HttpHeaders.contentLengthHeader, fileBytes.length.toString());
      request.headers.set(HttpHeaders.authorizationHeader, authHeader);
      request.add(fileBytes);

      final response = await request.close();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await response.drain();
        return _buildPublicUrl(key);
      } else {
        final body = await utf8.decoder.bind(response).join();
        throw Exception(
          'Gagal upload ke Cloudflare R2 (HTTP ${response.statusCode}): $body',
        );
      }
    } finally {
      client.close();
    }
  }

  /// Mengambil URL download/akses file.
  /// Pass-through jika path sudah berupa URL http(s).
  /// Mengembalikan string kosong jika path kosong atau terjadi error.
  Future<String> downloadUrl(String path) async {
    try {
      final trimmed = path.trim();
      if (trimmed.isEmpty) return '';
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return trimmed;
      }
      return _buildPublicUrl(trimmed);
    } catch (_) {
      return '';
    }
  }

  /// Membuat public URL berdasarkan konfigurasi [R2Config.publicBaseUrl]
  /// atau fallback ke endpoint S3 bucket.
  String _buildPublicUrl(String path) {
    final cleanKey = path.startsWith('/') ? path.substring(1) : path;
    final publicBase = R2Config.publicBaseUrl.trim();
    if (publicBase.isNotEmpty && !_isPlaceholder(publicBase)) {
      final cleanBase = publicBase.replaceAll(RegExp(r'/+$'), '');
      return '$cleanBase/$cleanKey';
    }

    final endpoint = R2Config.endpoint.trim().replaceAll(RegExp(r'/+$'), '');
    final bucket = R2Config.bucket.trim();
    return '$endpoint/$bucket/$cleanKey';
  }

  bool _isPlaceholder(String value) {
    return value.isEmpty || value.toUpperCase().contains('YOUR_');
  }

  String _getContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }
}
