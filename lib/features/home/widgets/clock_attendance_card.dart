import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

/// Kartu absen bahasa myadmin (mockup ~/workspace/mypresence-mockup/home.html).
/// Kartu putih: jam besar live, pill status, Masuk/Pulang, "Berikutnya",
/// tombol teal Absen Masuk/Pulang.
///
/// Menggantikan kartu "Tiket V2" (gradient biru/oranye/hijau + perforasi)
/// mengikuti mockup — cabang redesign ini adalah alternatifnya; Tiket V2
/// tetap ada di branch uti/firebase-mypresence-prod.
/// Props & logika status dipertahankan, kecuali lastLabel (tiket) yang dihapus.
class ClockAttendanceCard extends StatefulWidget {
  final String nextAction;
  final bool insideRadius;
  final bool hasIn;
  final bool hasOut;
  final String? checkInTime;
  final String? checkOutTime;
  final String? nextLabel;

  /// Label status khusus, mis. "Izin Disetujui" saat pengajuan hari ini
  /// disetujui. Bila null, label dihitung dari hasIn/hasOut.
  final String? statusLabel;
  final VoidCallback onPressed;

  const ClockAttendanceCard({
    super.key,
    required this.nextAction,
    required this.insideRadius,
    required this.hasIn,
    required this.hasOut,
    required this.onPressed,
    this.checkInTime,
    this.checkOutTime,
    this.nextLabel,
    this.statusLabel,
  });

  @override
  State<ClockAttendanceCard> createState() => _ClockAttendanceCardState();
}

class _ClockAttendanceCardState extends State<ClockAttendanceCard> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.nextAction == 'done' && widget.hasIn && widget.hasOut;
    final isClockOut = widget.nextAction == 'pulang' && !isDone;

    final checkIn = _formatTime(widget.checkInTime);
    final checkOut = _formatTime(widget.checkOutTime);
    final nextInfo = (widget.nextLabel?.trim().isNotEmpty ?? false)
        ? widget.nextLabel!.trim()
        : '-';

    final statusText = isDone
        ? 'Presensi Selesai'
        : widget.hasIn
            ? 'Sudah Absen Masuk'
            : (widget.statusLabel?.trim().isNotEmpty ?? false)
                ? widget.statusLabel!.trim()
                : 'Belum Ada Presensi';
    final statusIsDone = isDone || widget.hasIn;

    final clockText =
        '${_two(_now.hour)}:${_two(_now.minute)}:${_two(_now.second)}';

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clockText,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateLine(_now),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusIsDone
                      ? const Color(0xFFDCFCE7)
                      : AppColors.bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color:
                        statusIsDone ? AppColors.green : AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AppColors.line),
          ),
          Row(
            children: [
              Expanded(
                child: _TimeCell(label: 'Masuk', value: checkIn),
              ),
              Expanded(
                child: _TimeCell(label: 'Pulang', value: checkOut),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Berikutnya: $nextInfo',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          if (isDone)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Presensi Hari Ini Selesai',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(isClockOut ? 'Absen Pulang' : 'Absen Masuk'),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? '--:--' : text;
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _dateLine(DateTime date) {
    const weekdays = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
    ];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} '
        '${months[date.month - 1]} ${date.year}';
  }
}

class _TimeCell extends StatelessWidget {
  final String label;
  final String value;

  const _TimeCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
