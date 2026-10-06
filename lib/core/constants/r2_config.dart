class R2Config {
  /// Endpoint S3 API Cloudflare R2
  /// Contoh: `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`
  static const String endpoint = 'https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com';

  /// Nama bucket Cloudflare R2
  static const String bucket = 'YOUR_R2_BUCKET_NAME';

  /// Access Key ID dari Cloudflare R2 API Token
  static const String accessKeyId = 'YOUR_R2_ACCESS_KEY_ID';

  /// Secret Access Key dari Cloudflare R2 API Token
  static const String secretAccessKey = 'YOUR_R2_SECRET_ACCESS_KEY';

  /// Public Base URL untuk membaca/mengakses file secara publik
  /// Contoh: `https://pub-<hash>.r2.dev` atau domain kustom `https://cdn.example.com`
  static const String publicBaseUrl = 'https://pub-YOUR_HASH.r2.dev';
}
