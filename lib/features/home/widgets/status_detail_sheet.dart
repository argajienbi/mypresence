import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

class StatusDetailData {
  final String status;
  final String masuk;
  final String pulang;
  final String message;
  final double? distanceMeter;
  final bool insideRadius;
  final bool hasIn;
  final bool hasOut;
  final bool hasApprovedLeave;

  const StatusDetailData({
    required this.status,
    required this.masuk,
    required this.pulang,
    required this.message,
    required this.distanceMeter,
    required this.insideRadius,
    required this.hasIn,
    required this.hasOut,
    required this.hasApprovedLeave,
  });
}

Future<void> showStatusDetailSheet({
  required BuildContext context,
  required StatusDetailData data,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StatusDetailSheet(data: data),
  );
}

class _StatusDetailSheet extends StatelessWidget {
  final StatusDetailData data;

  const _StatusDetailSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    final statusColor = data.hasApprovedLeave
        ? AppColors.orange
        : data.hasOut || data.hasIn
            ? AppColors.green
            : AppColors.orange;
    final statusIcon = data.hasApprovedLeave
        ? Icons.event_available_rounded
        : data.hasOut
            ? Icons.done_all_rounded
            : data.hasIn
                ? Icons.check_rounded
                : Icons.hourglass_empty_rounded;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .88),
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .16),
              blurRadius: 30,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _IconBox(icon: Icons.assignment_turned_in_rounded, color: statusColor, size: 52),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Detail Status Hari Ini',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _CloseButton(onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 18),
              _SummaryCard(
                color: statusColor,
                icon: statusIcon,
                title: data.status,
                mainValue: data.hasOut ? data.pulang : data.hasIn ? data.masuk : '--:--',
                message: data.message,
              ),
              const SizedBox(height: 18),
              _Timeline(data: data),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MiniInfoCard(
                      icon: Icons.location_on_rounded,
                      color: data.insideRadius ? AppColors.green : AppColors.orange,
                      label: 'Lokasi / Jarak',
                      value: data.distanceMeter == null ? 'Belum tersedia' : '${data.distanceMeter!.round()} m dari kantor',
                      badge: data.insideRadius ? 'Lokasi Valid' : 'Di Luar Radius',
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _MiniInfoCard(
                      icon: Icons.camera_alt_rounded,
                      color: AppColors.blue,
                      label: 'Metode',
                      value: 'Selfie + GPS',
                      badge: 'Radius aktif',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String mainValue;
  final String message;

  const _SummaryCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.mainValue,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: .30)),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: .24),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  mainValue,
                  style: const TextStyle(color: AppColors.text, fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w700, height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final StatusDetailData data;

  const _Timeline({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimelineItem(
          title: 'Clock In',
          subtitle: data.hasIn ? 'Lokasi valid' : 'Belum dilakukan',
          time: data.masuk,
          badge: data.hasIn ? 'Selesai' : 'Menunggu',
          active: data.hasIn,
          color: AppColors.green,
          icon: Icons.login_rounded,
          isFirst: true,
        ),
        _TimelineItem(
          title: 'Clock Out',
          subtitle: data.hasOut ? 'Presensi selesai' : 'Belum dilakukan',
          time: data.pulang,
          badge: data.hasOut ? 'Selesai' : 'Menunggu',
          active: data.hasOut,
          color: AppColors.blue,
          icon: Icons.logout_rounded,
          isLast: true,
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String badge;
  final bool active;
  final Color color;
  final IconData icon;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.badge,
    required this.active,
    required this.color,
    required this.icon,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final visualColor = active ? color : AppColors.muted;
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                if (!isFirst) Expanded(child: Container(width: 2, color: AppColors.line)),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: active ? visualColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: visualColor.withValues(alpha: .55), width: 2),
                  ),
                  child: active ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: AppColors.line)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _IconBox(icon: icon, color: visualColor, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: visualColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(badge, style: TextStyle(color: visualColor, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String badge;

  const _MiniInfoCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBox(icon: icon, color: color, size: 46),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(999)),
            child: Text(badge, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _IconBox({required this.icon, required this.color, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(size * .32),
      ),
      child: Icon(icon, color: color, size: size * .48),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CloseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.line.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.close_rounded, color: AppColors.muted, size: 28),
        ),
      ),
    );
  }
}
