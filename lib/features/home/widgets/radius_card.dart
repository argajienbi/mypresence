import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../widgets/app_card.dart';
import 'leaflet_map_view.dart';

class RadiusCard extends StatelessWidget {
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

  const RadiusCard({
    super.key,
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

  @override
  Widget build(BuildContext context) {
    final label = loading ? 'Memuat Lokasi' : (inside ? 'Lokasi Valid' : 'Di Luar Radius');
    final badgeColor = loading ? AppColors.muted : (inside ? AppColors.green : AppColors.orange);

    return LayeredCurveCard(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 9),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Lokasi & Radius Absensi',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(inside ? Icons.check_circle_rounded : Icons.info_rounded, size: 15, color: badgeColor),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: TextStyle(
                        color: badgeColor,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 112,
              width: double.infinity,
              child: LeafletMapView(
                officeLat: officeLat,
                officeLng: officeLng,
                radiusMeter: radiusMeter,
                userLat: userLat,
                userLng: userLng,
                distanceMeter: distanceMeter,
                inside: inside,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  icon: Icons.my_location_rounded,
                  label: 'Radius: ${radiusMeter.round()} m',
                ),
              ),
              Container(width: 1, height: 22, color: AppColors.line),
              Expanded(
                child: _Metric(
                  icon: Icons.directions_walk_rounded,
                  label: 'Jarak: ${distanceMeter == null ? '--' : distanceMeter!.round()} m',
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool alignEnd;

  const _Metric({required this.icon, required this.label, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}
