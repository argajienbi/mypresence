import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/utils.dart';
import '../../widgets/app_card.dart';
import '../home/widgets/leaflet_map_view.dart';

Future<void> showAttendanceLocationSheet({
  required BuildContext context,
  required Map<String, dynamic> attendance,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AttendanceLocationSheet(attendance: attendance),
  );
}

class _AttendanceLocationSheet extends StatelessWidget {
  final Map<String, dynamic> attendance;

  const _AttendanceLocationSheet({required this.attendance});

  @override
  Widget build(BuildContext context) {
    final userLat = _userLatitude();
    final userLng = _userLongitude();
    final officeLat = _officeLatitude(userLat);
    final officeLng = _officeLongitude(userLng);
    final radius = _radiusMeter();
    final distance = _distanceMeter();
    final hasUserCoords = userLat != null && userLng != null;
    final inside = _geofenceStatus().toLowerCase() == 'inside' ||
        (radius > 0 && distance <= radius);

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: .92,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 12, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Lokasi Presensi',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _InfoLine(
                          label: 'Latitude', value: _formatDouble(userLat)),
                      const SizedBox(height: 6),
                      _InfoLine(
                          label: 'Longitude', value: _formatDouble(userLng)),
                      const SizedBox(height: 6),
                      _InfoLine(
                          label: 'Distance meter',
                          value: _formatDouble(distance, decimals: 0)),
                      const SizedBox(height: 6),
                      _InfoLine(
                          label: 'Radius meter',
                          value: _formatDouble(radius, decimals: 0)),
                      const SizedBox(height: 6),
                      _InfoLine(
                        label: 'Office latitude/longitude',
                        value:
                            '${_formatDouble(officeLat)}, ${_formatDouble(officeLng)}',
                      ),
                      const SizedBox(height: 6),
                      _InfoLine(
                          label: 'Geofence status', value: _geofenceStatus()),
                      const SizedBox(height: 6),
                      _InfoLine(
                          label: 'Location risk level', value: _riskLevel()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (hasUserCoords)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox(
                      height: 280,
                      child: LeafletMapView(
                        officeLat: officeLat ?? userLat,
                        officeLng: officeLng ?? userLng,
                        radiusMeter: radius > 0 ? radius : 100,
                        userLat: userLat,
                        userLng: userLng,
                        distanceMeter: distance,
                        inside: inside,
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'Lokasi tidak tersedia.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double? _userLatitude() {
    final value = asString(attendance['latitude']);
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  double? _userLongitude() {
    final value = asString(attendance['longitude']);
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }

  double? _officeLatitude(double? fallback) {
    final value = asString(attendance['office_latitude']);
    if (value.isNotEmpty) return double.tryParse(value);
    return fallback;
  }

  double? _officeLongitude(double? fallback) {
    final value = asString(attendance['office_longitude']);
    if (value.isNotEmpty) return double.tryParse(value);
    return fallback;
  }

  double _distanceMeter() {
    final value = asString(attendance['distance_meter']);
    return double.tryParse(value) ?? 0;
  }

  double _radiusMeter() {
    final value = asString(attendance['radius_meter']);
    return double.tryParse(value) ?? 0;
  }

  String _geofenceStatus() {
    final value = asString(attendance['geofence_status']);
    if (value.isNotEmpty) return value;
    final distance = _distanceMeter();
    final radius = _radiusMeter();
    if (distance > 0 && radius > 0) {
      return distance <= radius ? 'inside' : 'outside';
    }
    return '-';
  }

  String _riskLevel() {
    final value = asString(attendance['location_risk_level']);
    if (value.isNotEmpty) return value;
    if (attendance['mock_location_detected'] == true ||
        attendance['location_mock_detected'] == true) {
      return 'high';
    }
    if (attendance['location_accuracy_warning'] == true) {
      return 'warning';
    }
    return 'normal';
  }

  String _formatDouble(double? value, {int decimals = 6}) {
    if (value == null) return '-';
    return value.toStringAsFixed(decimals);
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
