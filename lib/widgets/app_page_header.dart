import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Satu-satunya bentuk header halaman dalam aplikasi (bahasa myadmin).
///
/// Teal datar solid [AppColors.primary] — TANPA gradient, TANPA wave/
/// lengkung. Dipakai semua halaman dalam (Home, Riwayat, Profil,
/// Pengajuan, Pengumuman, Detail Jadwal, form, halaman profil dalam,
/// WebView, ID Karyawan). Layar auth (splash/login/register) memakai
/// header brand-nya sendiri dan tidak memakai widget ini.
///
/// Bentuk: [SafeArea] (tanpa bottom) + konten setinggi 108, padding
/// 20/10/20/16. Baris judul: [leading] (kotak ikon 44) atau avatar
/// bulat 56 (Home), judul 19 w800 putih, subtitle 12.5 putih .85.
/// [showBack] menampilkan tombol kembali (pop) di kiri untuk halaman
/// dalam; tab root (Home/Riwayat/Profil) tidak memakainya. [extra]
/// merender konten tambahan di dalam area teal, di bawah baris judul
/// (dipakai tab Pengumuman/Notifikasi) — tingginya mengikuti isi.
class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? eyebrow;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final Widget? extra;
  final bool showBack;
  final VoidCallback? onBack;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.icon,
    this.leading,
    this.trailing,
    this.extra,
    this.showBack = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBack) ...[
                _HeaderButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: onBack ?? () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
              ],
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ] else if (icon != null) ...[
                _HeaderIconBox(icon: icon!),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null) ...[
                      Text(
                        eyebrow!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .80),
                          fontSize: 12,
                          height: 1.05,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .85),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          if (extra != null) ...[
            const SizedBox(height: 12),
            extra!,
          ],
        ],
      ),
    );

    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: extra == null
            ? SizedBox(height: 108, child: content)
            : content,
      ),
    );
  }
}

/// Kotak ikon header: 44x44, radius 12, putih .14 + border putih .35.
class _HeaderIconBox extends StatelessWidget {
  final IconData icon;

  const _HeaderIconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: .35),
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

/// Tombol 40x40 gaya header (kembali): putih .14 + border putih .35.
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: .35),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
