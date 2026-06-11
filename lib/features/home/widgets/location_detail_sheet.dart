import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_feedback.dart';
import 'leaflet_map_view.dart';

class LocationDetailData {
  final String officeName;
  final String address;
  final double officeLat;
  final double officeLng;
  final double? userLat;
  final double? userLng;
  final double? distanceMeter;
  final double radiusMeter;
  final bool inside;
  final bool loading;

  const LocationDetailData({
    required this.officeName,
    required this.address,
    required this.officeLat,
    required this.officeLng,
    required this.userLat,
    required this.userLng,
    required this.distanceMeter,
    required this.radiusMeter,
    required this.inside,
    required this.loading,
  });
}

Future<void> showLocationDetailSheet({
  required BuildContext context,
  required LocationDetailData data,
}) {
  return showAppBottomSheet<void>(
    context: context,
    child: _LocationDetailSheet(data: data),
  );
}

class _LocationDetailSheet extends StatelessWidget {
  final LocationDetailData data;

  const _LocationDetailSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    final statusColor = data.loading
        ? AppColors.muted
        : data.inside
            ? AppColors.green
            : AppColors.orange;
    final statusLabel = data.loading
        ? 'Memuat Lokasi'
        : data.inside
            ? 'Lokasi Valid'
            : 'Di Luar Radius';
    final statusIcon = data.loading
        ? Icons.sync_rounded
        : data.inside
            ? Icons.check_circle_rounded
            : Icons.info_rounded;
    final userLocation = _formatCoordinatePair(data.userLat, data.userLng);
    final officeLocation =
        _formatCoordinatePair(data.officeLat, data.officeLng);
    final distanceLabel = data.distanceMeter == null
        ? '--'
        : '${data.distanceMeter!.round()} m';

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    'Detail Lokasi Absensi',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 15),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data.officeName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 256,
                width: double.infinity,
                child: LeafletMapView(
                  officeLat: data.officeLat,
                  officeLng: data.officeLng,
                  radiusMeter: data.radiusMeter,
                  userLat: data.userLat,
                  userLng: data.userLng,
                  distanceMeter: data.distanceMeter,
                  inside: data.inside,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Radius kantor',
                    value: '${data.radiusMeter.round()} m',
                    icon: Icons.my_location_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Jarak user',
                    value: distanceLabel,
                    icon: Icons.directions_walk_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(14),
              radius: 22,
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Koordinat kantor',
                    value: officeLocation,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Koordinat user',
                    value: userLocation,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Status lokasi',
                    value: statusLabel,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Jarak dari kantor',
                    value: distanceLabel,
                  ),
                ],
              ),
            ),
            if (data.loading) ...[
              const SizedBox(height: 12),
              const _HintBox(
                icon: Icons.sync_rounded,
                text: 'Lokasi pengguna masih dimuat. Preview map tetap menampilkan titik kantor dan radius absensi.',
              ),
            ] else if (data.userLat == null || data.userLng == null) ...[
              const SizedBox(height: 12),
              const _HintBox(
                icon: Icons.gps_off_rounded,
                text: 'Lokasi pengguna belum tersedia, jadi jarak dan titik user bisa tampil sebagai placeholder.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCoordinatePair(double? lat, double? lng) {
    if (lat == null || lng == null) return '-';
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line.withValues(alpha: .65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _HintBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HintBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: .10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11.8,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
