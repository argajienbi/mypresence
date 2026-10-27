import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

/// Kartu lokasi bahasa myadmin (mockup ~/workspace/mypresence-mockup/home.html).
/// Kartu putih: ikon pin, nama + alamat kantor, pill status radius + jarak.
/// Menggantikan "Banner Biru" V4 — banner gradient + baris metrik dihapus
/// mengikuti mockup (cabang redesign ini adalah alternatifnya; V4 tetap
/// ada di branch uti/firebase-mypresence-prod).
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
        ? 'Memuat...'
        : (inside ? 'Dalam Radius' : 'Di Luar Radius');
    final pillColor = loading
        ? AppColors.muted
        : (inside ? AppColors.green : AppColors.red);
    final pillBg = loading
        ? AppColors.line
        : (inside
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2));
    final distanceLabel = distanceMeter == null
        ? '--'
        : '${distanceMeter!.round()} m dari kantor';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .07),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      officeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: pillColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    distanceLabel,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
