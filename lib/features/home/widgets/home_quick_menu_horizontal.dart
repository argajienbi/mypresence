import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

/// Menu cepat bahasa myadmin (mockup ~/workspace/mypresence-mockup/home.html).
/// Deret 7 ikon lingkaran teal + label — tanpa kartu, tanpa "Lihat semua"
/// (ketujuh menu sudah muat dalam satu baris).
/// Ketujuh aksi & tujuannya dipertahankan persis seperti sebelumnya.
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
        _MenuAction('Status', Icons.assignment_turned_in_rounded, onStatus),
        _MenuAction('Jadwal', Icons.calendar_month_rounded, onSchedule),
        _MenuAction('Izin', Icons.event_note_rounded, onIzin),
        _MenuAction('Sakit', Icons.medical_services_rounded, onSakit),
        _MenuAction('Cuti', Icons.work_history_rounded, onCuti),
        _MenuAction('Lembur', Icons.more_time_rounded, onLembur),
        _MenuAction('QR Teman', Icons.qr_code_2_rounded, onQrTeman),
      ];

  @override
  Widget build(BuildContext context) {
    final actions = _actions;

    return Row(
      children: [
        for (final action in actions)
          Expanded(child: _MenuItem(action: action)),
      ],
    );
  }
}

class _MenuAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuAction(this.label, this.icon, this.onTap);
}

class _MenuItem extends StatelessWidget {
  final _MenuAction action;

  const _MenuItem({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line, width: 1),
                ),
                child: Icon(
                  action.icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
