class R2Config {
  /// Endpoint S3 API Cloudflare R2
  /// Contoh: `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`
  static const String endpoint = String.fromEnvironment(
    'R2_ENDPOINT',
    defaultValue: 'https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com',
  );

  /// Nama bucket Cloudflare R2
  static const String bucket = String.fromEnvironment(
    'R2_BUCKET',
    defaultValue: 'YOUR_R2_BUCKET_NAME',
  );

  /// Access Key ID dari Cloudflare R2 API Token
  static const String accessKeyId = String.fromEnvironment(
    'R2_ACCESS_KEY_ID',
    defaultValue: 'YOUR_R2_ACCESS_KEY_ID',
  );

  /// Secret Access Key dari Cloudflare R2 API Token
  static const String secretAccessKey = String.fromEnvironment(
    'R2_SECRET_ACCESS_KEY',
    defaultValue: 'YOUR_R2_SECRET_ACCESS_KEY',
  );

  /// Public Base URL untuk membaca/mengakses file secara publik
  /// Contoh: `https://pub-<hash>.r2.dev` atau domain kustom `https://cdn.example.com`
  static const String publicBaseUrl = String.fromEnvironment(
    'R2_PUBLIC_URL',
    defaultValue: 'https://pub-YOUR_HASH.r2.dev',
  );

  /// Cek apakah kredensial sudah diisi (bukan placeholder)
  static bool get isConfigured =>
      !endpoint.contains('YOUR_') &&
      !bucket.contains('YOUR_') &&
      !accessKeyId.contains('YOUR_') &&
      !secretAccessKey.contains('YOUR_');
}
