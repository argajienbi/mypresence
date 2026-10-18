import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

/// Kartu lokasi V4 "Banner Biru" (dikunci 2026-10-19, mockup card-lokasi-v4).
/// Banner gradient biru + baris metrik putih. Peta pindah ke bottom sheet.
/// Seluruh props & perilaku onTap dipertahankan.
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
  final VoidCallback? onTap;

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
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = loading
        ? 'MEMUAT'
        : (inside ? 'DALAM RADIUS' : 'DI LUAR RADIUS');
    final distanceLabel =
        distanceMeter == null ? '--' : '${distanceMeter!.round()} m';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Banner biru
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Lokasi & Radius Absensi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Baris metrik putih
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10),
                  ),
                  border: Border.all(color: AppColors.line, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        label: 'RADIUS',
                        value: '${radiusMeter.round()} m',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: AppColors.line,
                    ),
                    Expanded(
                      child: _Metric(
                        label: 'JARAK ANDA',
                        value: distanceLabel,
                        highlight: !loading && !inside,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _Metric({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: .6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: highlight ? AppColors.accentDark : AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
