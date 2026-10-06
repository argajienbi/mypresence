import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mypresensi_flutter_stage3/core/utils/r2_signer.dart';

void main() {
  group('R2Crypto Test Vectors', () {
    test('SHA-256 standard test vectors', () {
      // Empty string
      expect(
        R2Crypto.hex(R2Crypto.sha256(utf8.encode(''))),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );

      // "abc"
      expect(
        R2Crypto.hex(R2Crypto.sha256(utf8.encode('abc'))),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );

      // Long message
      expect(
        R2Crypto.hex(R2Crypto.sha256(utf8.encode('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'))),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
      );
    });

    test('HMAC-SHA256 test vectors', () {
      final key = utf8.encode('key');
      final message = utf8.encode('The quick brown fox jumps over the lazy dog');
      expect(
        R2Crypto.hex(R2Crypto.hmacSha256(key, message)),
        'f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8',
      );
    });

    test('R2Signer formats amz date and date stamp correctly', () {
      final dt = DateTime.utc(2026, 10, 6, 11, 30, 45);
      expect(R2Signer.formatAmzDate(dt), '20261006T113045Z');
      expect(R2Signer.formatDateStamp(dt), '20261006');
    });

    test('R2Signer generates valid authorization header structure', () {
      final dt = DateTime.utc(2026, 10, 6, 11, 30, 45);
      final uri = Uri.parse('https://example.r2.cloudflarestorage.com/test-bucket/test.jpg');
      final payload = utf8.encode('test image content');

      final authHeader = R2Signer.createAuthorizationHeader(
        method: 'PUT',
        uri: uri,
        payload: payload,
        contentType: 'image/jpeg',
        accessKeyId: 'MY_KEY_ID',
        secretAccessKey: 'MY_SECRET_KEY',
        timestamp: dt,
      );

      expect(authHeader, contains('AWS4-HMAC-SHA256'));
      expect(authHeader, contains('Credential=MY_KEY_ID/20261006/auto/s3/aws4_request'));
      expect(authHeader, contains('SignedHeaders=content-length;content-type;host;x-amz-content-sha256;x-amz-date'));
      expect(authHeader, contains('Signature='));
    });
  });
}
