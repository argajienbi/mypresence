class PresenceSubmissionResult {
  final String photoQualityStatus;
  final String photoQualityWarning;
  final int photoFileSize;
  final int photoWidth;
  final int photoHeight;
  final String locationRiskLevel;
  final String locationWarning;
  final double locationAccuracy;
  final double distanceMeter;
  final bool locationMockDetected;

  const PresenceSubmissionResult({
    required this.photoQualityStatus,
    required this.photoQualityWarning,
    required this.photoFileSize,
    required this.photoWidth,
    required this.photoHeight,
    required this.locationRiskLevel,
    required this.locationWarning,
    required this.locationAccuracy,
    required this.distanceMeter,
    required this.locationMockDetected,
  });

  bool get hasWarnings =>
      photoQualityWarning.isNotEmpty || locationWarning.isNotEmpty;

  List<String> get warnings {
    final messages = <String>[];
    if (photoQualityWarning.isNotEmpty) {
      messages.add(photoQualityWarning);
    }
    if (locationWarning.isNotEmpty) {
      messages.add(locationWarning);
    }
    return messages;
  }
}
