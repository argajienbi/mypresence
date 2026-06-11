import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/request_status_item.dart';
import '../../core/utils.dart';
import '../../widgets/app_card.dart';
import '../../widgets/attachment_preview.dart';

Future<void> showRequestStatusDetailSheet({
  required BuildContext context,
  required RequestStatusItem item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RequestStatusDetailSheet(item: item),
  );
}

class _RequestStatusDetailSheet extends StatelessWidget {
  final RequestStatusItem item;

  const _RequestStatusDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: .94,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_kindIcon(item.kind), color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.kindLabel,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.contextLabel.isNotEmpty
                                ? item.contextLabel
                                : 'Detail Status Pengajuan',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: color,
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
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                  children: [
                    _SectionTitle('Info Umum'),
                    const SizedBox(height: 10),
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _InfoLine(
                              label: 'Jenis pengajuan', value: item.kindLabel),
                          const SizedBox(height: 6),
                          _InfoLine(
                              label: 'Status normalisasi',
                              value: item.statusLabel),
                          const SizedBox(height: 6),
                          _InfoLine(
                              label: 'Status asli / raw status',
                              value: _valueOrDash(item.rawStatus)),
                          const SizedBox(height: 6),
                          _InfoLine(
                              label: 'Tanggal pengajuan',
                              value: _valueOrDash(item.createdAtLabel)),
                          const SizedBox(height: 6),
                          _InfoLine(
                              label: 'Tanggal target / rentang tanggal',
                              value: _valueOrDash(item.targetDateLabel)),
                          const SizedBox(height: 6),
                          _InfoLine(
                              label: 'Tanggal diproses',
                              value: _valueOrDash(item.processedAtLabel)),
                          const SizedBox(height: 6),
                          _InfoLine(
                              label: 'Catatan user / alasan',
                              value: _valueOrDash(item.note)),
                          const SizedBox(height: 6),
                          _InfoLine(
                              label: 'Catatan admin',
                              value: _valueOrDash(item.adminNote)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle(item.isQr
                        ? 'Detail QR'
                        : item.isCorrection
                            ? 'Detail Koreksi'
                            : 'Detail Pengajuan'),
                    const SizedBox(height: 10),
                    if (item.isQr)
                      _QrDetailSection(item: item)
                    else if (item.isCorrection)
                      _CorrectionDetailSection(item: item)
                    else
                      _LeaveDetailSection(item: item),
                    const SizedBox(height: 16),
                    _SectionTitle(
                        item.hasEvidence ? item.evidenceLabel : 'Lampiran'),
                    const SizedBox(height: 10),
                    if (item.hasEvidence)
                      AttachmentPreviewTile(
                        photoUrl: item.evidenceUrl,
                        photoPath: item.evidencePath,
                        previewTitle: item.evidenceLabel,
                        buttonLabel: 'Lihat Foto',
                        warningMessage: _attachmentWarningMessage(item.raw),
                      )
                    else
                      const AppCard(
                        padding: EdgeInsets.all(14),
                        child: Text(
                          'Lampiran tidak tersedia.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
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

  static IconData _kindIcon(RequestStatusKind kind) {
    switch (kind) {
      case RequestStatusKind.leave:
        return Icons.event_note_rounded;
      case RequestStatusKind.qrTarget:
      case RequestStatusKind.qrHelper:
        return Icons.qr_code_2_rounded;
      case RequestStatusKind.correction:
        return Icons.edit_note_rounded;
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.green;
      case 'rejected':
        return AppColors.red;
      default:
        return AppColors.orange;
    }
  }

  String _valueOrDash(String value) => value.trim().isEmpty ? '-' : value;

  String _attachmentWarningMessage(Map<String, dynamic> row) {
    final warning = asString(row['photo_quality_warning']);
    if (warning.isNotEmpty) return warning;

    final status = asString(row['photo_quality_status']).toLowerCase();
    if (status == 'warning') {
      return 'Foto terlihat kurang jelas. Anda tetap bisa mengirim, tetapi admin mungkin perlu validasi tambahan.';
    }

    return '';
  }
}

class _LeaveDetailSection extends StatelessWidget {
  final RequestStatusItem item;

  const _LeaveDetailSection({required this.item});

  @override
  Widget build(BuildContext context) {
    final row = item.raw;
    final type = asString(row['type'], asString(row['leave_type'], 'izin'))
        .toLowerCase();

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _InfoLine(label: 'Jenis pengajuan', value: _leaveLabel(type)),
          const SizedBox(height: 6),
          _InfoLine(
              label: 'Tanggal mulai / selesai', value: _leaveDateRange(row)),
          const SizedBox(height: 6),
          _InfoLine(
              label: 'Alasan',
              value: _valueOrDash(
                  asString(row['reason'], asString(row['alasan'])))),
          const SizedBox(height: 6),
          _InfoLine(
              label: 'Lampiran',
              value: item.hasEvidence ? 'Tersedia' : 'Tidak ada'),
          const SizedBox(height: 6),
          _InfoLine(label: 'Status approval', value: item.statusLabel),
        ],
      ),
    );
  }

  String _leaveLabel(String type) {
    switch (type) {
      case 'sakit':
        return 'Sakit';
      case 'cuti':
        return 'Cuti';
      case 'lembur':
        return 'Lembur';
      default:
        return 'Izin';
    }
  }

  String _leaveDateRange(Map<String, dynamic> row) {
    final type = asString(row['type'], asString(row['leave_type'], 'izin'))
        .toLowerCase();
    if (type == 'lembur') {
      final date = asString(row['overtime_date'],
          asString(row['date_start'], asString(row['date'])));
      final start = asString(row['overtime_start_time']);
      final end = asString(row['overtime_end_time']);
      if (date.isEmpty) return '-';
      if (start.isEmpty || end.isEmpty) return date;
      return '$date - $start - $end';
    }

    final start = asString(row['date_start'],
        asString(row['tanggal_mulai'], asString(row['date'])));
    final end =
        asString(row['date_end'], asString(row['tanggal_selesai'], start));
    if (start.isEmpty && end.isEmpty) return '-';
    if (start == end) return start;
    return '$start - $end';
  }
}

class _QrDetailSection extends StatelessWidget {
  final RequestStatusItem item;

  const _QrDetailSection({required this.item});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _InfoLine(label: 'Konteks', value: _valueOrDash(item.contextLabel)),
          const SizedBox(height: 6),
          _InfoLine(
              label: 'Target name / uid',
              value: _joinNameUid(item.targetName, item.targetUid)),
          const SizedBox(height: 6),
          _InfoLine(
              label: 'Helper name / uid',
              value: _joinNameUid(item.helperName, item.helperUid)),
          const SizedBox(height: 6),
          _InfoLine(label: 'Action type', value: _actionLabel(item.actionType)),
          const SizedBox(height: 6),
          _InfoLine(
            label: 'Photo evidence status',
            value: item.hasEvidence
                ? 'Foto bukti tersedia'
                : 'Foto bukti belum tersedia',
          ),
        ],
      ),
    );
  }
}

class _CorrectionDetailSection extends StatelessWidget {
  final RequestStatusItem item;

  const _CorrectionDetailSection({required this.item});

  @override
  Widget build(BuildContext context) {
    final row = item.raw;
    final oldSnapshot = row['old_attendance_snapshot'];
    final oldAttendance = oldSnapshot is Map && oldSnapshot.isNotEmpty
        ? asMap(oldSnapshot)
        : asMap(row['old_attendance']);
    final hasOldAttendance = oldAttendance.isNotEmpty;

    return Column(
      children: [
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _InfoLine(
                  label: 'Tanggal koreksi',
                  value: _valueOrDash(item.targetDateLabel)),
              const SizedBox(height: 6),
              _InfoLine(
                  label: 'Tipe koreksi',
                  value: _correctionLabel(asString(row['correction_type']))),
              const SizedBox(height: 6),
              _InfoLine(
                  label: 'Jam masuk yang diajukan',
                  value:
                      _valueOrDash(asString(row['requested_check_in_time']))),
              const SizedBox(height: 6),
              _InfoLine(
                  label: 'Jam pulang yang diajukan',
                  value:
                      _valueOrDash(asString(row['requested_check_out_time']))),
              const SizedBox(height: 6),
              _InfoLine(
                  label: 'Lampiran',
                  value: item.hasEvidence ? 'Tersedia' : 'Tidak ada'),
              const SizedBox(height: 6),
              _InfoLine(
                  label: 'Admin note', value: _valueOrDash(item.adminNote)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Presensi Lama',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              if (hasOldAttendance)
                Column(
                  children: [
                    _InfoLine(
                      label: 'Clock In',
                      value: _nestedTime(oldAttendance['masuk']),
                    ),
                    const SizedBox(height: 6),
                    _InfoLine(
                      label: 'Clock Out',
                      value: _nestedTime(oldAttendance['pulang']),
                    ),
                    const SizedBox(height: 6),
                    _InfoLine(
                      label: 'Metode',
                      value: _methodValue(
                          oldAttendance['masuk'], oldAttendance['pulang']),
                    ),
                    const SizedBox(height: 6),
                    _InfoLine(
                      label: 'Status',
                      value: _statusValue(
                          oldAttendance['masuk'], oldAttendance['pulang']),
                    ),
                  ],
                )
              else
                const Text(
                  'Belum ada data presensi pada tanggal ini.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _correctionLabel(String value) {
    switch (value.toLowerCase()) {
      case 'masuk':
        return 'Masuk';
      case 'pulang':
        return 'Pulang';
      case 'masuk_pulang':
        return 'Masuk & Pulang';
      default:
        return _valueOrDash(value);
    }
  }

  String _nestedTime(dynamic rowValue) {
    final row = asMap(rowValue);
    if (row.isEmpty) return '-';
    final value = asString(row['time'], asString(row['waktu']));
    return value.isEmpty ? '-' : value;
  }

  String _methodValue(dynamic masukValue, dynamic pulangValue) {
    final masuk = asMap(masukValue);
    final pulang = asMap(pulangValue);
    final method =
        asString(masuk['method'], asString(pulang['method'])).toLowerCase();
    if (method == 'qr') return 'QR';
    if (method == 'selfie') return 'Selfie';
    return '-';
  }

  String _statusValue(dynamic masukValue, dynamic pulangValue) {
    final masuk = asMap(masukValue);
    final pulang = asMap(pulangValue);
    final value = asString(
      masuk['attendance_status'],
      asString(
        masuk['status'],
        asString(
          pulang['attendance_status'],
          asString(pulang['status']),
        ),
      ),
    );
    return value.isEmpty ? '-' : value;
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
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: AppColors.text,
      ),
    );
  }
}

String _joinNameUid(String name, String uid) {
  final cleanName = name.trim();
  final cleanUid = uid.trim();
  if (cleanName.isEmpty && cleanUid.isEmpty) return '-';
  if (cleanName.isEmpty) return cleanUid;
  if (cleanUid.isEmpty) return cleanName;
  return '$cleanName - $cleanUid';
}

String _actionLabel(String action) {
  switch (action.toLowerCase()) {
    case 'pulang':
      return 'pulang';
    case 'masuk':
      return 'masuk';
    default:
      return _valueOrDash(action);
  }
}

String _valueOrDash(String value) => value.trim().isEmpty ? '-' : value;
