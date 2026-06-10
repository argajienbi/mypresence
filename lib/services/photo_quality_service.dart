import 'dart:io';
import 'dart:ui' as ui;

class PhotoQualityCheckResult {
  final String status;
  final String message;
  final int fileSize;
  final int width;
  final int height;

  const PhotoQualityCheckResult({
    required this.status,
    required this.message,
    required this.fileSize,
    required this.width,
    required this.height,
  });

  bool get isValid => status != 'invalid';
  bool get hasWarning => status == 'warning' && message.isNotEmpty;
  bool get shouldBlock => status == 'invalid';

  factory PhotoQualityCheckResult.valid({
    required int fileSize,
    required int width,
    required int height,
  }) {
    return PhotoQualityCheckResult(
      status: 'valid',
      message: '',
      fileSize: fileSize,
      width: width,
      height: height,
    );
  }

  factory PhotoQualityCheckResult.warning({
    required int fileSize,
    required int width,
    required int height,
    required String message,
  }) {
    return PhotoQualityCheckResult(
      status: 'warning',
      message: message,
      fileSize: fileSize,
      width: width,
      height: height,
    );
  }

  factory PhotoQualityCheckResult.invalid({
    String message = 'Foto belum valid. Silakan ulangi foto.',
  }) {
    return PhotoQualityCheckResult(
      status: 'invalid',
      message: message,
      fileSize: 0,
      width: 0,
      height: 0,
    );
  }
}

class PhotoQualityService {
  static const String warningMessage =
      'Foto terlihat kurang jelas. Anda tetap bisa mengirim, tetapi admin mungkin perlu validasi tambahan.';

  Future<PhotoQualityCheckResult> validate(File file) async {
    try {
      if (!await file.exists()) {
        return PhotoQualityCheckResult.invalid();
      }

      final fileSize = await file.length();
      if (fileSize <= 0) {
        return PhotoQualityCheckResult.invalid();
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return PhotoQualityCheckResult.invalid();
      }

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final width = frame.image.width;
      final height = frame.image.height;
      frame.image.dispose();

      if (width < 300 || height < 300) {
        return PhotoQualityCheckResult.invalid();
      }

      final minSide = width < height ? width : height;
      if (fileSize < 12 * 1024 || minSide < 600) {
        return PhotoQualityCheckResult.warning(
          fileSize: fileSize,
          width: width,
          height: height,
          message: warningMessage,
        );
      }

      return PhotoQualityCheckResult.valid(
        fileSize: fileSize,
        width: width,
        height: height,
      );
    } catch (_) {
      return PhotoQualityCheckResult.invalid();
    }
  }
}
