import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_session.dart';
import '../../core/models/request_status_item.dart';
import '../../core/utils.dart';
import '../../services/schedule_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/attachment_preview.dart';
import 'attendance_location_sheet.dart';
import '../corrections/attendance_correction_form_page.dart';
import 'history_models.dart';

Future<void> showAttendanceDetailSheet({
  required BuildContext context,
  required AppSession session,
  required DailyHistoryStatus item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AttendanceDetailSheet(session: session, item: item),
  );
}

class _AttendanceDetailSheet extends StatelessWidget {
  final AppSession session;
  final DailyHistoryStatus item;

  const _AttendanceDetailSheet({
    required this.session,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final attendance = item.attendanceRow ?? <String, dynamic>{};
    final masuk = _nestedMap(attendance['masuk']);
    final pulang = _nestedMap(attendance['pulang']);
    final hasAttendance = masuk != null || pulang != null;
    final canRequestCorrection = hasAttendance || item.status == 'alpa';
    final hasQr = _isQrRecord(attendance);
    final statusColor = _statusColor(item.status);
    final statusIcon = _statusIcon(item.status);
    final statusLabel = _statusLabel(item.status);
    final statusMessage = _statusMessage(item.status);
    final locationWarning = _locationWarning(attendance, masuk, pulang);
    final qualityWarning = _qualityWarning(attendance, masuk, pulang);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .90,
        ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _IconBox(
                    icon: statusIcon,
                    color: statusColor,
                    size: 52,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Presensi',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppDate.dayDate(item.date),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _CloseButton(onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 18),
              _SummaryCard(
                color: statusColor,
                icon: statusIcon,
                title: statusLabel,
                mainValue: _mainValue(attendance, masuk, pulang),
                message: statusMessage,
              ),
              const SizedBox(height: 18),
              _SectionTitle('Info Utama'),
              const SizedBox(height: 10),
              _GridInfo(
                children: [
                  _MiniInfoCard(
                    icon: Icons.badge_outlined,
                    color: AppColors.primary,
                    label: 'Metode',
                    value: _methodLabel(attendance, masuk, pulang),
                    badge: _sourceLabel(attendance),
                  ),
                  _MiniInfoCard(
                    icon: Icons.check_circle_outline_rounded,
                    color: _statusChipColor(attendance),
                    label: 'Validasi',
                    value: asString(attendance['validation_status'],
                        asString(attendance['status'], '-')),
                    badge: asString(attendance['geofence_status'], 'unknown'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _GridInfo(
                children: [
                  _MiniInfoCard(
                    icon: Icons.location_on_rounded,
                    color: _locationColor(attendance),
                    label: 'Lokasi',
                    value: _locationValue(attendance),
                    badge: _distanceBadge(attendance),
                  ),
                  _MiniInfoCard(
                    icon: Icons.business_rounded,
                    color: AppColors.blue,
                    label: 'Unit Kerja',
                    value: _officeValue(attendance),
                    badge: _groupValue(attendance),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _LocationDetailCard(
                attendance: attendance,
                onViewLocation: _hasLocation(attendance)
                    ? () => showAttendanceLocationSheet(
                          context: context,
                          attendance: attendance,
                        )
                    : null,
              ),
              if (locationWarning.isNotEmpty || qualityWarning.isNotEmpty) ...[
                const SizedBox(height: 14),
                if (locationWarning.isNotEmpty)
                  _WarningCard(
                    icon: Icons.location_on_rounded,
                    color: AppColors.orange,
                    title: 'Flag Lokasi',
                    message: locationWarning,
                  ),
                if (qualityWarning.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _WarningCard(
                    icon: Icons.camera_alt_rounded,
                    color: AppColors.orange,
                    title: 'Kualitas Foto',
                    message: qualityWarning,
                  ),
                ],
              ],
              if (_hasPhotoInfo(masuk) || _hasPhotoInfo(pulang)) ...[
                const SizedBox(height: 18),
                _SectionTitle('Foto Presensi'),
                const SizedBox(height: 10),
                if (_hasPhotoInfo(masuk))
                  _PhotoCard(
                    title: 'Foto Clock In',
                    subtitle: _timeLabel(masuk),
                    photoUrl: _photoUrl(masuk),
                    photoPath: _photoPath(masuk),
                    badge: _photoBadge(masuk),
                  ),
                if (_hasPhotoInfo(masuk) && _hasPhotoInfo(pulang))
                  const SizedBox(height: 10),
                if (_hasPhotoInfo(pulang))
                  _PhotoCard(
                    title: 'Foto Clock Out',
                    subtitle: _timeLabel(pulang),
                    photoUrl: _photoUrl(pulang),
                    photoPath: _photoPath(pulang),
                    badge: _photoBadge(pulang),
                  ),
              ],
              const SizedBox(height: 18),
              if (hasAttendance) ...[
                _SectionTitle('Clock In / Clock Out'),
                const SizedBox(height: 10),
                _AttendanceTimeline(
                  masuk: masuk,
                  pulang: pulang,
                  schedule: item.schedule,
                ),
                const SizedBox(height: 18),
              ],
              if (_hasScheduleInfo(item.schedule)) ...[
                _SectionTitle('Jadwal Saat Itu'),
                const SizedBox(height: 10),
                _ScheduleCard(schedule: item.schedule!),
                const SizedBox(height: 18),
              ],
              if (_hasLeaveInfo(item.leaveRow)) ...[
                _SectionTitle('Detail Pengajuan'),
                const SizedBox(height: 10),
                _LeaveDetailCard(row: item.leaveRow!),
                const SizedBox(height: 18),
              ],
              if (_hasOvertimeInfo(item.overtimeRow)) ...[
                _SectionTitle('Detail Lembur'),
                const SizedBox(height: 10),
                _OvertimeDetailCard(row: item.overtimeRow!),
                const SizedBox(height: 18),
              ],
              if (hasQr) ...[
                _SectionTitle('Data QR'),
                const SizedBox(height: 10),
                _QrDetailCard(attendance: attendance),
                const SizedBox(height: 18),
              ],
              if (canRequestCorrection)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => AttendanceCorrectionFormPage(
                            session: session,
                            initialDate: item.date,
                            oldAttendance: item.attendanceRow,
                          ),
                        ),
                      );
                      if (result == true && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text(
                      'Ajukan Koreksi',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      side: const BorderSide(color: AppColors.line),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic>? _nestedMap(dynamic value) {
    if (value is! Map) return null;
    return value.map((key, val) => MapEntry(key.toString(), val));
  }

  bool _hasLeaveInfo(Map<String, dynamic>? row) {
    return row != null && row.isNotEmpty;
  }

  bool _hasOvertimeInfo(Map<String, dynamic>? row) {
    return row != null && row.isNotEmpty;
  }

  bool _hasScheduleInfo(DailySchedule? schedule) {
    return schedule != null &&
        (schedule.workStart.isNotEmpty ||
            schedule.workEnd.isNotEmpty ||
            schedule.shiftName.isNotEmpty ||
            schedule.timetableName.isNotEmpty);
  }

  bool _hasPhotoInfo(Map<String, dynamic>? row) {
    if (row == null) return false;
    return _photoUrl(row).isNotEmpty || asString(row['photo_path']).isNotEmpty;
  }

  bool _hasLocation(Map<String, dynamic> attendance) {
    return asString(attendance['latitude']).isNotEmpty ||
        asString(attendance['longitude']).isNotEmpty;
  }

  bool _isQrRecord(Map<String, dynamic> attendance) {
    return attendance['created_by_qr'] == true ||
        asString(attendance['proxy_request_id']).isNotEmpty ||
        asString(attendance['method']).toLowerCase() == 'qr';
  }

  String _timeLabel(Map<String, dynamic>? row) {
    if (row == null) return '--:--';
    return asString(row['time'], asString(row['waktu'], '--:--'));
  }

  String _photoUrl(Map<String, dynamic>? row) {
    if (row == null) return '';
    return asString(row['photo_url']);
  }

  String _photoPath(Map<String, dynamic>? row) {
    if (row == null) return '';
    return asString(row['photo_path']);
  }

  String _photoBadge(Map<String, dynamic>? row) {
    if (row == null) return 'Tidak ada foto';
    final quality = asString(row['photo_quality_status']);
    if (quality == 'warning') return 'Perlu Validasi';
    if (quality == 'invalid') return 'Tidak Valid';
    return _timeLabel(row);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'hadir':
        return 'Hadir';
      case 'telat':
        return 'Telat';
      case 'alpa':
        return 'Alpa';
      case 'izin':
        return 'Izin';
      case 'sakit':
        return 'Sakit';
      case 'cuti':
        return 'Cuti';
      case 'lembur':
        return 'Lembur';
      case 'jadwal':
        return 'Jadwal';
      case 'libur':
        return 'Libur';
      default:
        return 'Presensi';
    }
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'hadir':
        return 'Clock In dan Clock Out tercatat dengan baik.';
      case 'telat':
        return 'Clock In tercatat melewati jam kerja yang dijadwalkan.';
      case 'alpa':
        return 'Tidak ada presensi dan tidak ada keterangan pada hari kerja ini.';
      case 'izin':
      case 'sakit':
      case 'cuti':
        return 'Hari ini tercatat sebagai pengajuan ${_statusLabel(status)}.';
      case 'lembur':
        return 'Lembur disetujui dan tercatat di riwayat.';
      case 'jadwal':
        return 'Jadwal tersedia, namun waktu presensi belum tiba.';
      case 'libur':
        return 'Hari ini merupakan hari libur atau non-aktif.';
      default:
        return 'Detail presensi harian.';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'hadir':
        return AppColors.green;
      case 'telat':
        return AppColors.orange;
      case 'alpa':
      case 'sakit':
        return AppColors.red;
      case 'cuti':
        return const Color(0xFFCE7A00);
      case 'izin':
        return AppColors.blue;
      case 'lembur':
        return AppColors.primary;
      case 'libur':
        return const Color(0xFF8A94A6);
      default:
        return AppColors.muted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'hadir':
        return Icons.event_available_rounded;
      case 'telat':
        return Icons.schedule_rounded;
      case 'alpa':
        return Icons.person_off_rounded;
      case 'sakit':
        return Icons.medical_services_rounded;
      case 'cuti':
        return Icons.work_history_rounded;
      case 'izin':
        return Icons.event_note_rounded;
      case 'lembur':
        return Icons.timelapse_rounded;
      case 'jadwal':
        return Icons.event_available_rounded;
      case 'libur':
        return Icons.beach_access_rounded;
      default:
        return Icons.assignment_turned_in_rounded;
    }
  }

  String _mainValue(
    Map<String, dynamic> attendance,
    Map<String, dynamic>? masuk,
    Map<String, dynamic>? pulang,
  ) {
    if (masuk != null && pulang != null) {
      return '${_timeOf(attendance, 'masuk')} - ${_timeOf(attendance, 'pulang')}';
    }
    if (masuk != null) {
      return _timeOf(attendance, 'masuk');
    }
    if (pulang != null) {
      return _timeOf(attendance, 'pulang');
    }
    return '--:--';
  }

  String _timeOf(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is Map) {
      return (value['time'] ?? value['waktu'] ?? '--:--').toString();
    }
    return '--:--';
  }

  String _methodLabel(
    Map<String, dynamic> attendance,
    Map<String, dynamic>? masuk,
    Map<String, dynamic>? pulang,
  ) {
    final method = asString(attendance['method']).toLowerCase();
    if (method.isNotEmpty) {
      return method == 'qr' ? 'QR' : 'Selfie';
    }
    if (masuk != null) {
      final nested = asString(masuk['method']).toLowerCase();
      if (nested.isNotEmpty) {
        return nested == 'qr' ? 'QR' : 'Selfie';
      }
    }
    if (pulang != null) {
      final nested = asString(pulang['method']).toLowerCase();
      if (nested.isNotEmpty) {
        return nested == 'qr' ? 'QR' : 'Selfie';
      }
    }
    return 'Selfie';
  }

  String _sourceLabel(Map<String, dynamic> attendance) {
    final source = asString(attendance['source'], 'mobile_app').toLowerCase();
    if (source.isNotEmpty) return source;
    return 'mobile_app';
  }

  Color _statusChipColor(Map<String, dynamic> attendance) {
    final status = asString(
        attendance['validation_status'], asString(attendance['status']));
    switch (RequestStatusItem.normalizeStatus(status)) {
      case 'approved':
        return AppColors.green;
      case 'rejected':
        return AppColors.red;
      default:
        return AppColors.orange;
    }
  }

  Color _locationColor(Map<String, dynamic> attendance) {
    final risk = asString(attendance['location_risk_level']).toLowerCase();
    final mocked = attendance['mock_location_detected'] == true ||
        attendance['location_mock_detected'] == true;
    if (mocked || risk == 'suspicious' || risk == 'high') return AppColors.red;
    if (risk == 'warning' || attendance['location_accuracy_warning'] == true) {
      return AppColors.orange;
    }
    return AppColors.green;
  }

  String _locationValue(Map<String, dynamic> attendance) {
    final latitude = asString(attendance['latitude']);
    final longitude = asString(attendance['longitude']);
    if (latitude.isEmpty && longitude.isEmpty) return '-';
    return '$latitude, $longitude';
  }

  String _distanceBadge(Map<String, dynamic> attendance) {
    final distance = math.max(0,
        (double.tryParse(asString(attendance['distance_meter'])) ?? 0).round());
    final radius = math.max(0,
        (double.tryParse(asString(attendance['radius_meter'])) ?? 0).round());
    if (distance <= 0 && radius <= 0) return 'Lokasi';
    if (radius <= 0) return '$distance m';
    return '$distance / $radius m';
  }

  String _officeValue(Map<String, dynamic> attendance) {
    final office = asString(attendance['office_name']);
    final department = asString(attendance['department_name']);
    if (office.isEmpty && department.isEmpty) return '-';
    if (department.isEmpty) return office;
    return '$office - $department';
  }

  String _groupValue(Map<String, dynamic> attendance) {
    final group = asString(attendance['group_name']);
    if (group.isEmpty) return '-';
    return group;
  }

  String _locationWarning(
    Map<String, dynamic> attendance,
    Map<String, dynamic>? masuk,
    Map<String, dynamic>? pulang,
  ) {
    final direct = asString(attendance['location_warning']);
    if (direct.isNotEmpty) return direct;
    final directMock = asString(attendance['location_mock_warning']);
    if (directMock.isNotEmpty) return directMock;
    final nestedIn = asString(masuk?['location_warning']);
    if (nestedIn.isNotEmpty) return nestedIn;
    final nestedInMock = asString(masuk?['location_mock_warning']);
    if (nestedInMock.isNotEmpty) return nestedInMock;
    final nestedOut = asString(pulang?['location_warning']);
    if (nestedOut.isNotEmpty) return nestedOut;
    final nestedOutMock = asString(pulang?['location_mock_warning']);
    if (nestedOutMock.isNotEmpty) return nestedOutMock;
    return '';
  }

  String _qualityWarning(
    Map<String, dynamic> attendance,
    Map<String, dynamic>? masuk,
    Map<String, dynamic>? pulang,
  ) {
    final direct = asString(attendance['photo_quality_warning']);
    if (direct.isNotEmpty) return direct;
    final nestedIn = asString(masuk?['photo_quality_warning']);
    if (nestedIn.isNotEmpty) return nestedIn;
    final nestedOut = asString(pulang?['photo_quality_warning']);
    if (nestedOut.isNotEmpty) return nestedOut;
    return '';
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
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  mainValue,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridInfo extends StatelessWidget {
  final List<Widget> children;

  const _GridInfo({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: children.first),
        const SizedBox(width: 12),
        Expanded(child: children.last),
      ],
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
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _WarningCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBox(icon: icon, color: color, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppColors.text,
      ),
    );
  }
}

class _AttendanceTimeline extends StatelessWidget {
  final Map<String, dynamic>? masuk;
  final Map<String, dynamic>? pulang;
  final DailySchedule? schedule;

  const _AttendanceTimeline({
    required this.masuk,
    required this.pulang,
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimelineItem(
          title: 'Clock In',
          subtitle: _clockInSubtitle(),
          time: _timeValue(masuk),
          badge: _clockInBadge(),
          active: masuk != null,
          color: AppColors.green,
          icon: Icons.login_rounded,
          isFirst: true,
        ),
        _TimelineItem(
          title: 'Clock Out',
          subtitle: _clockOutSubtitle(),
          time: _timeValue(pulang),
          badge: _clockOutBadge(),
          active: pulang != null,
          color: AppColors.blue,
          icon: Icons.logout_rounded,
          isLast: true,
        ),
      ],
    );
  }

  String _timeValue(Map<String, dynamic>? row) {
    if (row == null) return '--:--';
    return asString(row['time'], asString(row['waktu'], '--:--'));
  }

  String _clockInSubtitle() {
    if (masuk == null) return 'Belum dilakukan';
    final status =
        asString(masuk?['attendance_status'], asString(masuk?['status']));
    if (status.toLowerCase().contains('late') ||
        status.toLowerCase().contains('telat')) {
      return 'Clock In tercatat telat';
    }
    return 'Clock In tercatat';
  }

  String _clockOutSubtitle() {
    if (pulang == null) return 'Belum dilakukan';
    if (asString(pulang?['early_out']).toLowerCase() == 'true' ||
        pulang?['early_out'] == true) {
      return 'Clock Out tercatat pulang awal';
    }
    return 'Clock Out tercatat';
  }

  String _clockInBadge() {
    if (masuk == null) return 'Menunggu';
    final status =
        asString(masuk?['attendance_status'], asString(masuk?['status']))
            .toLowerCase();
    if (status.contains('late') || status.contains('telat')) return 'Telat';
    return 'Selesai';
  }

  String _clockOutBadge() {
    if (pulang == null) return 'Menunggu';
    if (asString(pulang?['early_out']).toLowerCase() == 'true' ||
        pulang?['early_out'] == true) {
      return 'Pulang Awal';
    }
    return 'Selesai';
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
                if (!isFirst)
                  Expanded(child: Container(width: 2, color: AppColors.line)),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: active ? visualColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: visualColor.withValues(alpha: .55), width: 2),
                  ),
                  child: active
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : null,
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: AppColors.line)),
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
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: visualColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: visualColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final DailySchedule schedule;

  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLine(
              label: 'Shift',
              value: schedule.shiftName.isEmpty ? '-' : schedule.shiftName),
          const SizedBox(height: 6),
          _InfoLine(
              label: 'Timetable',
              value: schedule.timetableName.isEmpty
                  ? '-'
                  : schedule.timetableName),
          const SizedBox(height: 6),
          _InfoLine(
              label: 'Work start / end',
              value: _pair(schedule.workStart, schedule.workEnd)),
          const SizedBox(height: 6),
          _InfoLine(
              label: 'Clock In window',
              value: _pair(schedule.checkInStart, schedule.checkInEnd)),
          const SizedBox(height: 6),
          _InfoLine(
              label: 'Clock Out window',
              value: _pair(schedule.checkOutStart, schedule.checkOutEnd)),
          const SizedBox(height: 6),
          _InfoLine(
            label: 'Telat / Pulang Awal',
            value:
                '${schedule.lateToleranceMinute} / ${schedule.earlyOutToleranceMinute} menit',
          ),
          const SizedBox(height: 6),
          _InfoLine(label: 'Schedule source', value: schedule.source),
        ],
      ),
    );
  }

  String _pair(String start, String end) {
    if (start.isEmpty && end.isEmpty) return '-';
    return '$start - $end';
  }
}

class _PhotoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String photoUrl;
  final String photoPath;
  final String badge;

  const _PhotoCard({
    required this.title,
    required this.subtitle,
    required this.photoUrl,
    required this.photoPath,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          AttachmentPreviewTile(
            photoUrl: photoUrl,
            photoPath: photoPath,
            previewTitle: title,
          ),
        ],
      ),
    );
  }
}

class _LocationDetailCard extends StatelessWidget {
  final Map<String, dynamic> attendance;
  final VoidCallback? onViewLocation;

  const _LocationDetailCard({
    required this.attendance,
    required this.onViewLocation,
  });

  @override
  Widget build(BuildContext context) {
    final latitude = _doubleValue(attendance['latitude']);
    final longitude = _doubleValue(attendance['longitude']);
    final distance = _doubleValue(attendance['distance_meter']);
    final radius = _doubleValue(attendance['radius_meter']);
    final officeLat = _doubleValue(attendance['office_latitude']);
    final officeLng = _doubleValue(attendance['office_longitude']);
    final geofence = asString(attendance['geofence_status'], '-');
    final riskLevel = asString(attendance['location_risk_level'], '-');

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Lokasi',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _InfoLine(label: 'Latitude', value: _formatValue(latitude)),
          const SizedBox(height: 6),
          _InfoLine(label: 'Longitude', value: _formatValue(longitude)),
          const SizedBox(height: 6),
          _InfoLine(
              label: 'Distance meter',
              value: _formatValue(distance, decimals: 0)),
          const SizedBox(height: 6),
          _InfoLine(
              label: 'Radius meter', value: _formatValue(radius, decimals: 0)),
          const SizedBox(height: 6),
          _InfoLine(
            label: 'Office latitude/longitude',
            value: '${_formatValue(officeLat)}, ${_formatValue(officeLng)}',
          ),
          const SizedBox(height: 6),
          _InfoLine(label: 'Geofence status', value: geofence),
          const SizedBox(height: 6),
          _InfoLine(label: 'Location risk level', value: riskLevel),
          const SizedBox(height: 10),
          if (onViewLocation != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onViewLocation,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Lihat Lokasi'),
              ),
            )
          else
            const Text(
              'Lokasi tidak tersedia.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(asString(value)) ?? 0;
  }

  String _formatValue(double value, {int decimals = 6}) {
    if (value == 0) return '-';
    return value.toStringAsFixed(decimals);
  }
}

class _LeaveDetailCard extends StatelessWidget {
  final Map<String, dynamic> row;

  const _LeaveDetailCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final type = asString(row['type'], asString(row['leave_type'], 'izin'))
        .toLowerCase();
    final attachment =
        asString(row['attachment_url'], asString(row['attachment_path']));
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLine(label: 'Jenis', value: _leaveLabel(type)),
          const SizedBox(height: 6),
          _InfoLine(label: 'Tanggal', value: _leaveDateValue(type)),
          const SizedBox(height: 6),
          _InfoLine(
              label: 'Alasan',
              value: asString(row['reason'], asString(row['alasan'], '-'))),
          const SizedBox(height: 6),
          _InfoLine(
              label: 'Lampiran',
              value: attachment.isNotEmpty ? 'Tersedia' : 'Tidak ada'),
          const SizedBox(height: 6),
          _InfoLine(
              label: 'Catatan admin', value: asString(row['admin_note'], '-')),
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

  String _leaveDateValue(String type) {
    if (type == 'lembur') {
      final date = asString(row['overtime_date'],
          asString(row['date_start'], asString(row['date'], '-')));
      final start = asString(row['overtime_start_time']);
      final end = asString(row['overtime_end_time']);
      if (start.isEmpty || end.isEmpty) return date;
      return '$date - $start - $end';
    }
    final start = asString(row['date_start'],
        asString(row['tanggal_mulai'], asString(row['date'], '-')));
    final end =
        asString(row['date_end'], asString(row['tanggal_selesai'], start));
    if (start == end) return start;
    return '$start - $end';
  }
}

class _OvertimeDetailCard extends StatelessWidget {
  final Map<String, dynamic> row;

  const _OvertimeDetailCard({required this.row});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLine(
            label: 'Tanggal',
            value: asString(row['overtime_date'],
                asString(row['date_start'], asString(row['date'], '-'))),
          ),
          const SizedBox(height: 6),
          _InfoLine(
            label: 'Jam',
            value:
                '${asString(row['overtime_start_time'], '-')} - ${asString(row['overtime_end_time'], '-')}',
          ),
          const SizedBox(height: 6),
          _InfoLine(
            label: 'Durasi',
            value: '${asString(row['overtime_duration_minute'], '0')} menit',
          ),
          const SizedBox(height: 6),
          _InfoLine(
            label: 'Alasan',
            value: asString(row['reason'], asString(row['alasan'], '-')),
          ),
          const SizedBox(height: 6),
          _InfoLine(
            label: 'Catatan admin',
            value: asString(row['admin_note'], '-'),
          ),
        ],
      ),
    );
  }
}

class _QrDetailCard extends StatelessWidget {
  final Map<String, dynamic> attendance;

  const _QrDetailCard({required this.attendance});

  @override
  Widget build(BuildContext context) {
    final helperUid = _helperUid();
    final helperName = _helperName();
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLine(label: 'QR Helper UID', value: helperUid),
          const SizedBox(height: 6),
          _InfoLine(label: 'QR Helper Name', value: helperName),
          const SizedBox(height: 6),
          _InfoLine(
            label: 'Proxy Request ID / QR Request ID',
            value: asString(attendance['proxy_request_id'], '-'),
          ),
          const SizedBox(height: 6),
          _InfoLine(
            label: 'Created by QR',
            value: attendance['created_by_qr'] == true ? 'Ya' : 'Tidak',
          ),
        ],
      ),
    );
  }

  String _helperUid() {
    final createdByUid = asString(attendance['created_by_uid']);
    final helperUid = asString(attendance['helper_uid']);
    if (helperUid.isNotEmpty) return helperUid;
    if (attendance['created_by_qr'] == true) {
      return createdByUid.isEmpty ? '-' : createdByUid;
    }
    return '-';
  }

  String _helperName() {
    final createdByName = asString(attendance['created_by_name']);
    final helperName = asString(attendance['helper_name']);
    if (helperName.isNotEmpty) return helperName;
    if (attendance['created_by_qr'] == true) {
      return createdByName.isEmpty ? '-' : createdByName;
    }
    return '-';
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _IconBox({
    required this.icon,
    required this.color,
    this.size = 44,
  });

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
