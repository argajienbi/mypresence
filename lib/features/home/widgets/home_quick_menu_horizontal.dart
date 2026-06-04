import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../widgets/app_card.dart';

class HomeQuickMenuHorizontal extends StatelessWidget {
  final VoidCallback onStatus;
  final VoidCallback onSchedule;
  final VoidCallback onIzin;
  final VoidCallback onSakit;
  final VoidCallback onCuti;
  final VoidCallback onLembur;
  final VoidCallback onQrTeman;

  const HomeQuickMenuHorizontal({
    super.key,
    required this.onStatus,
    required this.onSchedule,
    required this.onIzin,
    required this.onSakit,
    required this.onCuti,
    required this.onLembur,
    required this.onQrTeman,
  });

  List<_MenuAction> get _actions => [
        _MenuAction(
          label: 'Status',
          icon: Icons.assignment_turned_in_rounded,
          color: const Color(0xFF7A8793),
          onTap: onStatus,
        ),
        _MenuAction(
          label: 'Detail Jadwal',
          icon: Icons.event_available_rounded,
          color: AppColors.primary,
          onTap: onSchedule,
        ),
        _MenuAction(
          label: 'Izin',
          icon: Icons.event_note_rounded,
          color: AppColors.primary,
          onTap: onIzin,
        ),
        _MenuAction(
          label: 'Sakit',
          icon: Icons.medical_services_rounded,
          color: AppColors.red,
          onTap: onSakit,
        ),
        _MenuAction(
          label: 'Cuti',
          icon: Icons.work_rounded,
          color: AppColors.orange,
          onTap: onCuti,
        ),
        _MenuAction(
          label: 'Lembur',
          icon: Icons.more_time_rounded,
          color: const Color(0xFF7C3AED),
          onTap: onLembur,
        ),
        _MenuAction(
          label: 'QR',
          icon: Icons.qr_code_2_rounded,
          color: AppColors.green,
          onTap: onQrTeman,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final actions = _actions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menu Cepat',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Akses cepat ke fitur penting harian.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showAllMenu(context, actions),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Lihat semua',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (int index = 0; index < actions.length; index++) ...[
                _MenuItem(action: actions[index]),
                SizedBox(width: index == actions.length - 1 ? 4 : 12),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showAllMenu(BuildContext context, List<_MenuAction> actions) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .14),
                  blurRadius: 28,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Semua Menu Cepat',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih fitur yang ingin digunakan.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: actions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 10,
                    childAspectRatio: .82,
                  ),
                  itemBuilder: (context, index) {
                    return _MenuItem(
                      action: actions[index],
                      onTapOverride: () {
                        Navigator.of(context).pop();
                        actions[index].onTap();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MenuAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _MenuItem extends StatelessWidget {
  final _MenuAction action;
  final VoidCallback? onTapOverride;

  const _MenuItem({required this.action, this.onTapOverride});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTapOverride ?? action.onTap,
        child: SizedBox(
          width: 76,
          height: 76,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: Text(
                    action.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
