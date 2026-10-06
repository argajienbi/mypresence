import 'dart:convert';
import 'dart:typed_data';

/// Utilitas kalkulasi SHA-256 dan HMAC-SHA256 murni Dart
/// untuk otentikasi AWS Signature Version 4 (Cloudflare R2 S3-Compatible).
class R2Crypto {
  static const List<int> _k = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  static Uint8List sha256(List<int> data) {
    var h0 = 0x6a09e667;
    var h1 = 0xbb67ae85;
    var h2 = 0x3c6ef372;
    var h3 = 0xa54ff53a;
    var h4 = 0x510e527f;
    var h5 = 0x9b05688c;
    var h6 = 0x1f83d9ab;
    var h7 = 0x5be0cd19;

    final length = data.length;
    final bitLength = length * 8;

    final remainder = (length + 9) % 64;
    final paddingLength = remainder == 0 ? 0 : 64 - remainder;
    final totalLength = length + 1 + paddingLength + 8;
    final padded = Uint8List(totalLength);
    padded.setRange(0, length, data);
    padded[length] = 0x80;

    final byteData = ByteData.sublistView(padded);
    byteData.setUint64(totalLength - 8, bitLength, Endian.big);

    final w = Uint32List(64);

    for (var i = 0; i < totalLength; i += 64) {
      for (var t = 0; t < 16; t++) {
        w[t] = byteData.getUint32(i + (t * 4), Endian.big);
      }

      for (var t = 16; t < 64; t++) {
        final s0 = _rotr(w[t - 15], 7) ^ _rotr(w[t - 15], 18) ^ (w[t - 15] >>> 3);
        final s1 = _rotr(w[t - 2], 17) ^ _rotr(w[t - 2], 19) ^ (w[t - 2] >>> 10);
        w[t] = (w[t - 16] + s0 + w[t - 7] + s1) & 0xFFFFFFFF;
      }

      var a = h0;
      var b = h1;
      var c = h2;
      var d = h3;
      var e = h4;
      var f = h5;
      var g = h6;
      var h = h7;

      for (var t = 0; t < 64; t++) {
        final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final notE = (~e) & 0xFFFFFFFF;
        final ch = (e & f) ^ (notE & g);
        final temp1 = (h + s1 + ch + _k[t] + w[t]) & 0xFFFFFFFF;
        final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (s0 + maj) & 0xFFFFFFFF;

        h = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xFFFFFFFF;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xFFFFFFFF;
      }

      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
      h5 = (h5 + f) & 0xFFFFFFFF;
      h6 = (h6 + g) & 0xFFFFFFFF;
      h7 = (h7 + h) & 0xFFFFFFFF;
    }

    final result = Uint8List(32);
    final outView = ByteData.sublistView(result);
    outView.setUint32(0, h0, Endian.big);
    outView.setUint32(4, h1, Endian.big);
    outView.setUint32(8, h2, Endian.big);
    outView.setUint32(12, h3, Endian.big);
    outView.setUint32(16, h4, Endian.big);
    outView.setUint32(20, h5, Endian.big);
    outView.setUint32(24, h6, Endian.big);
    outView.setUint32(28, h7, Endian.big);
    return result;
  }

  static Uint8List hmacSha256(List<int> key, List<int> data) {
    var k = Uint8List.fromList(key);
    if (k.length > 64) {
      k = sha256(k);
    }
    final ipad = Uint8List(64);
    final opad = Uint8List(64);
    for (var i = 0; i < 64; i++) {
      final b = i < k.length ? k[i] : 0;
      ipad[i] = b ^ 0x36;
      opad[i] = b ^ 0x5c;
    }

    final inner = Uint8List(64 + data.length);
    inner.setRange(0, 64, ipad);
    inner.setRange(64, inner.length, data);
    final innerHash = sha256(inner);

    final outer = Uint8List(64 + 32);
    outer.setRange(0, 64, opad);
    outer.setRange(64, outer.length, innerHash);
    return sha256(outer);
  }

  static String hex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  static int _rotr(int x, int n) => ((x >>> n) | (x << (32 - n))) & 0xFFFFFFFF;
}

/// Signer untuk membuat header otentikasi AWS SigV4
class R2Signer {
  static String formatAmzDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    String four(int n) => n.toString().padLeft(4, '0');
    return '${four(dt.year)}${two(dt.month)}${two(dt.day)}T${two(dt.hour)}${two(dt.minute)}${two(dt.second)}Z';
  }

  static String formatDateStamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    String four(int n) => n.toString().padLeft(4, '0');
    return '${four(dt.year)}${two(dt.month)}${two(dt.day)}';
  }

  static String createAuthorizationHeader({
    required String method,
    required Uri uri,
    required List<int> payload,
    required String contentType,
    required String accessKeyId,
    required String secretAccessKey,
    required DateTime timestamp,
    String region = 'auto',
    String service = 's3',
  }) {
    final amzDate = formatAmzDate(timestamp);
    final dateStamp = formatDateStamp(timestamp);
    final payloadHash = R2Crypto.hex(R2Crypto.sha256(payload));

    final canonicalUri =
        uri.path.split('/').map((s) => s.isEmpty ? '' : Uri.encodeComponent(s)).join('/');

    final canonicalHeaders =
        'content-length:${payload.length}\n'
        'content-type:$contentType\n'
        'host:${uri.host}\n'
        'x-amz-content-sha256:$payloadHash\n'
        'x-amz-date:$amzDate\n';

    const signedHeaders = 'content-length;content-type;host;x-amz-content-sha256;x-amz-date';

    final canonicalRequest =
        '$method\n'
        '$canonicalUri\n'
        '\n'
        '$canonicalHeaders\n'
        '$signedHeaders\n'
        '$payloadHash';

    final canonicalRequestHash =
        R2Crypto.hex(R2Crypto.sha256(utf8.encode(canonicalRequest)));

    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final stringToSign =
        'AWS4-HMAC-SHA256\n'
        '$amzDate\n'
        '$credentialScope\n'
        '$canonicalRequestHash';

    final kSecret = utf8.encode('AWS4$secretAccessKey');
    final kDate = R2Crypto.hmacSha256(kSecret, utf8.encode(dateStamp));
    final kRegion = R2Crypto.hmacSha256(kDate, utf8.encode(region));
    final kService = R2Crypto.hmacSha256(kRegion, utf8.encode(service));
    final kSigning = R2Crypto.hmacSha256(kService, utf8.encode('aws4_request'));

    final signature =
        R2Crypto.hex(R2Crypto.hmacSha256(kSigning, utf8.encode(stringToSign)));

    return 'AWS4-HMAC-SHA256 Credential=$accessKeyId/$credentialScope, '
        'SignedHeaders=$signedHeaders, '
        'Signature=$signature';
  }
}
