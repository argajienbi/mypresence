import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracy;
  const LocationResult({required this.latitude, required this.longitude, required this.accuracy});
}

class LocationService {
  Future<LocationResult> currentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('GPS belum aktif.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw Exception('Izin lokasi ditolak.');

    final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
    return LocationResult(latitude: p.latitude, longitude: p.longitude, accuracy: p.accuracy);
  }

  double distanceMeter({required double fromLat, required double fromLng, required double toLat, required double toLng}) {
    return Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
  }
}
