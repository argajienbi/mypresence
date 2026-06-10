import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracy;
  final bool isMocked;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.isMocked,
  });
}

class LocationAssessment {
  final String riskLevel;
  final String warningMessage;
  final String mockWarningMessage;
  final bool accuracyWarning;
  final bool mockDetected;

  const LocationAssessment({
    required this.riskLevel,
    required this.warningMessage,
    required this.mockWarningMessage,
    required this.accuracyWarning,
    required this.mockDetected,
  });

  bool get hasWarning => warningMessage.isNotEmpty;
}

class LocationService {
  Future<LocationResult> currentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('GPS belum aktif.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw Exception('Izin lokasi ditolak.');

    final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
    return LocationResult(latitude: p.latitude, longitude: p.longitude, accuracy: p.accuracy, isMocked: p.isMocked);
  }

  double distanceMeter({required double fromLat, required double fromLng, required double toLat, required double toLng}) {
    return Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
  }

  LocationAssessment assessLocation(LocationResult location) {
    if (location.isMocked) {
      return const LocationAssessment(
        riskLevel: 'high',
        warningMessage: 'Lokasi perangkat terdeteksi mencurigakan. Data presensi akan diberi tanda untuk validasi admin.',
        mockWarningMessage: 'Lokasi perangkat terdeteksi mencurigakan. Data presensi akan diberi tanda untuk validasi admin.',
        accuracyWarning: false,
        mockDetected: true,
      );
    }

    if (location.accuracy > 100) {
      return const LocationAssessment(
        riskLevel: 'high',
        warningMessage: 'Akurasi lokasi kurang stabil. Data presensi akan diberi tanda untuk validasi admin.',
        mockWarningMessage: '',
        accuracyWarning: true,
        mockDetected: false,
      );
    }

    if (location.accuracy > 50) {
      return const LocationAssessment(
        riskLevel: 'warning',
        warningMessage: 'Akurasi lokasi kurang stabil. Data presensi akan diberi tanda untuk validasi admin.',
        mockWarningMessage: '',
        accuracyWarning: true,
        mockDetected: false,
      );
    }

    return const LocationAssessment(
      riskLevel: 'normal',
      warningMessage: '',
      mockWarningMessage: '',
      accuracyWarning: false,
      mockDetected: false,
    );
  }
}
