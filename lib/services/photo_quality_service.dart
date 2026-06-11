import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

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
  static const int maxUploadFileSizeBytes = 1024 * 1024;
  static const int maxUploadSidePx = 1600;
  static const int minUploadSidePx = 600;
  static const String warningMessage =
      'Kualitas foto standar. Admin dapat memvalidasi jika diperlukan.';

  Future<File> prepareForUpload(File file) async {
    if (!await file.exists()) {
      throw Exception('Foto tidak ditemukan. Silakan ambil foto ulang.');
    }

    final fileSize = await file.length();
    if (fileSize <= 0) {
      throw Exception('Foto belum valid. Silakan ulangi foto.');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Foto belum valid. Silakan ulangi foto.');
    }

    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Foto belum bisa diproses. Silakan ulangi foto.');
    }

    final normalized = img.bakeOrientation(decoded);
    final longestSide = math.max(normalized.width, normalized.height);
    final needsResize =
        longestSide > maxUploadSidePx || fileSize > maxUploadFileSizeBytes;
    if (!needsResize) {
      return file;
    }

    final candidates = <int>{
      math.min(longestSide, maxUploadSidePx),
      1440,
      1280,
    }.where((side) => side > 0 && side <= longestSide).toList();

    if (candidates.isEmpty) {
      candidates.add(longestSide);
    }

    final qualities = <int>[85, 80, 75];
    final tempDir = Directory('${Directory.systemTemp.path}/mypresensi');
    await tempDir.create(recursive: true);

    for (final targetSide in candidates) {
      final resized = _resizeToSide(normalized, targetSide);
      for (final quality in qualities) {
        final encoded = img.encodeJpg(resized, quality: quality);
        if (encoded.length > maxUploadFileSizeBytes) {
          continue;
        }

        final output = File(
          '${tempDir.path}/photo_${DateTime.now().microsecondsSinceEpoch}_${targetSide}_q$quality.jpg',
        );
        await output.writeAsBytes(encoded, flush: true);
        return output;
      }
    }

    throw Exception(
      'Ukuran foto masih terlalu besar. Silakan ulangi foto agar file lebih ringan.',
    );
  }

  Future<PhotoQualityCheckResult> validate(File file) async {
    try {
      if (!await file.exists()) {
        return PhotoQualityCheckResult.invalid();
      }

      final fileSize = await file.length();
      if (fileSize <= 0) {
        return PhotoQualityCheckResult.invalid();
      }
      if (fileSize > maxUploadFileSizeBytes) {
        return PhotoQualityCheckResult.invalid(
          message:
              'Ukuran foto masih terlalu besar. Silakan ulangi foto agar file lebih ringan.',
        );
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
      if (fileSize < 12 * 1024 || minSide < minUploadSidePx) {
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

  img.Image _resizeToSide(img.Image source, int targetSide) {
    if (source.width <= targetSide && source.height <= targetSide) {
      return source;
    }

    if (source.width >= source.height) {
      return img.copyResize(source, width: targetSide);
    }

    return img.copyResize(source, height: targetSide);
  }
}
