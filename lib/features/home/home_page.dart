import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_notification.dart';
import '../../core/models/app_session.dart';
import '../../core/utils.dart';
import '../../services/app_notification_service.dart';
import '../../services/attendance_reminder_service.dart';
import '../../services/attendance_service.dart';
import '../../services/leave_service.dart';
import '../../services/local_notification_service.dart';
import '../../services/location_service.dart';
import '../../services/schedule_service.dart';
import '../../widgets/app_feedback.dart';
import '../attendance/camera_presence_page.dart';
import '../leave/leave_form_page.dart';
import '../notifications/notifications_page.dart';
import '../proxy_qr/proxy_attendance_page.dart';
import 'widgets/clock_attendance_card.dart';
import 'widgets/home_announcement_card.dart';
import 'widgets/home_quick_menu_horizontal.dart';
import 'widgets/home_sticky_profile_header.dart';
import 'widgets/home_info_tile.dart';
import 'widgets/home_schedule_preview.dart';
import 'widgets/radius_card.dart';

class HomePage extends StatefulWidget {
  final AppSession session;
  final bool showScheduleOnOpen;
  final VoidCallback? onScheduleShown;

  const HomePage({
    super.key,
    required this.session,
    this.showScheduleOnOpen = false,
    this.onScheduleShown,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AttendanceService _attendance = AttendanceService();
  final LocationService _location = LocationService();
  final ScheduleService _scheduleService = ScheduleService();
  final LeaveService _leaveService = LeaveService();
  final AppNotificationService _notificationService = AppNotificationService();

  Timer? _timer;
  Timer? _schedulePollTimer;
  String _date = AppDate.dayDate(DateTime.now());
  double? _distance;
  double? _userLat;
  double? _userLng;
  bool _insideRadius = false;
  bool _loadingLocation = true;
  Map<String, dynamic>? _today;
  DailySchedule? _schedule;
  Map<String, dynamic>? _approvedLeaveToday;
  bool _loadingSchedule = true;
  String _lastScheduleFingerprint = '';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _date = AppDate.dayDate(DateTime.now()));
    });
    _schedulePollTimer = Timer.periodic(
        const Duration(minutes: 5), (_) => _loadSchedule(notifyChange: true));
    _refresh().then((_) {
      if (!mounted || !widget.showScheduleOnOpen) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onScheduleShown?.call();
        _showScheduleDetails();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _schedulePollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadLocation(),
      _loadToday(),
      _loadSchedule(),
      _loadApprovedLeaveToday(),
    ]);
    await _scheduleAttendanceReminders();
  }

  Future<void> _loadLocation() async {
    try {
      final loc = await _location.currentLocation();
      final distance = _location.distanceMeter(
        fromLat: loc.latitude,
        fromLng: loc.longitude,
        toLat: widget.session.officeLatitude,
        toLng: widget.session.officeLongitude,
      );
      if (!mounted) return;
      setState(() {
        _userLat = loc.latitude;
        _userLng = loc.longitude;
        _distance = distance;
        _insideRadius = distance <= widget.session.officeRadiusMeter;
        _loadingLocation = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _loadToday() async {
    final data = await _attendance.todayAttendance(widget.session);
    if (mounted) setState(() => _today = data);
  }

  Future<void> _loadSchedule({bool notifyChange = false}) async {
    try {
      final data = await _scheduleService.resolveToday(widget.session);
      final nextFingerprint = _scheduleFingerprint(data);
      final changed = notifyChange &&
          _lastScheduleFingerprint.isNotEmpty &&
          _lastScheduleFingerprint != nextFingerprint;
      if (!mounted) return;
      setState(() {
        _schedule = data;
        _loadingSchedule = false;
        _lastScheduleFingerprint = nextFingerprint;
      });
      await _scheduleAttendanceReminders();
      if (changed) await _showScheduleChangedNotification(data);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _schedule = null;
        _loadingSchedule = false;
      });
    }
  }

  Future<void> _loadApprovedLeaveToday() async {
    try {
      final data = await _leaveService.getApprovedLeaveForDate(
        session: widget.session,
        date: DateTime.now(),
      );
      if (mounted) setState(() => _approvedLeaveToday = data);
    } catch (_) {
      if (mounted) setState(() => _approvedLeaveToday = null);
    }
  }

  Future<void> _scheduleAttendanceReminders() async {
    if (_approvedLeaveToday != null) return;
    await AttendanceReminderService.scheduleToday(
      session: widget.session,
      schedule: _schedule,
      hasIn: hasIn,
      hasOut: hasOut,
    );
  }

  Future<void> _showScheduleChangedNotification(DailySchedule schedule) async {
    await LocalNotificationService.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Jadwal Kerja Diperbarui',
      body: schedule.isWorkday
          ? 'Jadwal hari ini: ${_workTime(schedule)}.'
          : schedule.message,
      payload: {
        'ref_type': 'schedule',
        'type': 'info',
        'title': 'Jadwal Kerja Diperbarui',
        'body': schedule.isWorkday
            ? 'Jadwal hari ini: ${_workTime(schedule)}.'
            : schedule.message,
      },
    );
  }

  String _scheduleFingerprint(DailySchedule schedule) {
    return [
      schedule.source,
      schedule.assignmentId,
      schedule.shiftId,
      schedule.shiftName,
      schedule.timetableId,
      schedule.timetableName,
      schedule.workStart,
      schedule.workEnd,
      schedule.checkInStart,
      schedule.checkInEnd,
      schedule.checkOutStart,
      schedule.checkOutEnd,
      schedule.message,
      schedule.isWorkday.toString(),
      schedule.isHoliday.toString(),
      schedule.overtimeScheduleId,
      schedule.overtimeFlag.toString(),
    ].join('|');
  }

  bool get hasIn => _today?['masuk'] is Map;
  bool get hasOut => _today?['pulang'] is Map;

  String get nextAction {
    if (!hasIn) return 'masuk';
    if (!hasOut) return 'pulang';
    return 'done';
  }

  Future<void> _openAttendance() async {
    if (nextAction == 'done') return;

    final leave = _approvedLeaveToday;
    if (leave != null) {
      final type = _leaveTypeLabel(
          (leave['type'] ?? leave['leave_type'] ?? '').toString());
      AppToast.info(context,
          'Hari ini pengajuan $type Anda sudah disetujui. Absen tidak wajib dilakukan.');
      return;
    }

    if (_loadingSchedule) {
      AppToast.info(
          context, 'Jadwal kerja masih dimuat. Coba beberapa saat lagi.');
      return;
    }

    DailySchedule? schedule = _schedule;
    try {
      schedule ??= await _scheduleService.resolveToday(widget.session);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(
          context, 'Jadwal kerja belum bisa dibaca. Coba muat ulang aplikasi.');
      return;
    }
    if (!mounted) return;

    final window = _scheduleService.validateAction(
      schedule: schedule,
      actionType: nextAction,
    );

    if (!window.allowed) {
      final message = window.status.startsWith('outside_')
          ? 'Di luar jam absen. ${window.message}'
          : window.message;
      AppToast.error(context, message);
      return;
    }

    if (_loadingLocation) {
      AppToast.info(context, 'Lokasi masih dimuat. Coba beberapa saat lagi.');
      return;
    }

    if (!_insideRadius) {
      final distanceText = _distance == null
          ? ''
          : ' (${_distance!.toStringAsFixed(0)} m dari kantor)';
      AppToast.error(
          context, 'Anda berada di luar radius kantor$distanceText.');
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraPresencePage(
          session: widget.session,
          actionType: nextAction,
        ),
      ),
    );
    await _refresh();
  }

  void _openLeave(String type) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LeaveFormPage(session: widget.session, type: type),
    ));
  }

  void _openQrTeman() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProxyAttendancePage(session: widget.session),
    ));
  }

  void _openNotifications() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NotificationsPage(session: widget.session),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final status = hasOut
        ? 'Presensi Hari Ini Selesai'
        : hasIn
            ? 'Sudah Absen Masuk'
            : _approvedLeaveToday != null
                ? '${_leaveTypeLabel((_approvedLeaveToday!['type'] ?? _approvedLeaveToday!['leave_type'] ?? '').toString())} Disetujui'
                : 'Belum Ada Presensi';
    final masuk = hasIn
        ? ((_today!['masuk'] as Map)['time'] ??
                (_today!['masuk'] as Map)['waktu'] ??
                '--:--')
            .toString()
        : '--:--';
    final pulang = hasOut
        ? ((_today!['pulang'] as Map)['time'] ??
                (_today!['pulang'] as Map)['waktu'] ??
                '--:--')
            .toString()
        : '--:--';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Content ListView
          Positioned.fill(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 170, 18, 96),
              children: [
                if (_approvedLeaveToday != null) ...[
                  _ApprovedLeaveBanner(
                    type: _leaveTypeLabel((_approvedLeaveToday!['type'] ??
                            _approvedLeaveToday!['leave_type'] ??
                            '')
                        .toString()),
                    reason: (_approvedLeaveToday!['reason'] ??
                            _approvedLeaveToday!['alasan'] ??
                            '')
                        .toString(),
                  ),
                  const SizedBox(height: 12),
                ],
                RadiusCard(
                  officeName: widget.session.officeName,
                  address: widget.session.officeAddress,
                  officeLat: widget.session.officeLatitude,
                  officeLng: widget.session.officeLongitude,
                  userLat: _userLat,
                  userLng: _userLng,
                  distanceMeter: _distance,
                  radiusMeter: widget.session.officeRadiusMeter,
                  inside: _insideRadius,
                  loading: _loadingLocation,
                ),
                const SizedBox(height: 12),
                ClockAttendanceCard(
                  nextAction: nextAction,
                  insideRadius: _insideRadius,
                  hasIn: hasIn,
                  hasOut: hasOut,
                  onPressed: _openAttendance,
                ),
                const SizedBox(height: 18),
                const Text('Menu Cepat',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text)),
                const SizedBox(height: 9),
                HomeQuickMenuHorizontal(
                  onStatus: () => _showStatusDetails(
                      status: status, masuk: masuk, pulang: pulang),
                  onSchedule: _showScheduleDetails,
                  onIzin: () => _openLeave('izin'),
                  onSakit: () => _openLeave('sakit'),
                  onCuti: () => _openLeave('cuti'),
                  onLembur: () => _openLeave('lembur'),
                  onQrTeman: _openQrTeman,
                ),
                const SizedBox(height: 16),
                HomeAnnouncementCard(session: widget.session),
              ],
            ),
          ),
          // Sticky Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: StreamBuilder<List<AppNotification>>(
              stream: _notificationService.watchFirestoreInbox(widget.session),
              builder: (context, firestoreSnapshot) {
                final firestoreItems =
                    firestoreSnapshot.data ?? const <AppNotification>[];
                return StreamBuilder<List<AppNotification>>(
                  stream:
                      _notificationService.watchRtdbFallback(widget.session),
                  builder: (context, rtdbSnapshot) {
                    final rtdbItems =
                        rtdbSnapshot.data ?? const <AppNotification>[];
                    // Filter hanya untuk notifikasi penting (bukan announcement/pengumuman)
                    final allItems = _notificationService.mergeInbox(
                        firestoreItems, rtdbItems);
                    final importantItems = allItems
                        .where((item) =>
                            !item.read &&
                            _isImportantNotification(item.refType))
                        .toList();
                    final unreadCount = importantItems.length;

                    return HomeStickyProfileHeader(
                      session: widget.session,
                      date: _date,
                      unreadNotifications: unreadCount,
                      onNotificationPressed: _openNotifications,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isImportantNotification(String refType) {
    const importantTypes = [
      'approval',
      'leave',
      'schedule',
      'jadwal',
      'attendance',
      'system'
    ];
    return importantTypes.contains(refType.toLowerCase());
  }

  void _showScheduleDetails() {
    final schedule = _schedule;
    final readyText = _loadingSchedule
        ? 'Memuat'
        : schedule == null
            ? 'Belum tersedia'
            : schedule.isHoliday
                ? 'Libur'
                : schedule.isWorkday
                    ? 'Aktif'
                    : 'Tidak Aktif';
    final statusColor = schedule != null && schedule.isWorkday
        ? AppColors.green
        : AppColors.orange;

    _showDetailSheet(
      title: 'Detail Jadwal',
      icon: Icons.event_available_rounded,
      iconColor: AppColors.primary,
      children: [
        HomeSchedulePreview(
          session: widget.session,
          scheduleService: _scheduleService,
          todaySchedule: _schedule,
          loadingToday: _loadingSchedule,
          onOpenTodayDetail: () {},
        ),
        const SizedBox(height: 12),
        _DetailRow(
            icon: Icons.schedule_rounded,
            label: 'Shift Hari Ini',
            value: _scheduleText(schedule?.shiftName,
                fallback: schedule?.timetableName ?? '-')),
        _DetailRow(
            icon: Icons.groups_rounded,
            label: 'Grup / Struktur',
            value: _groupLabel()),
        _DetailRow(
            icon: Icons.access_time_rounded,
            label: 'Jam Kerja Hari Ini',
            value: _workTime(schedule)),
        _DetailRow(
            icon: Icons.date_range_rounded,
            label: 'Berlaku',
            value: schedule?.overtimeFlag == true
                ? 'Tanggal lembur terjadwal'
                : 'Sesuai penerapan jadwal aktif'),
        _DetailRow(
            icon: Icons.receipt_long_rounded,
            label: 'Sumber Jadwal',
            value: _sourceLabel(schedule?.source ?? '-')),
        _DetailRow(
            icon: Icons.verified_user_rounded,
            label: 'Status',
            value: readyText,
            valueColor: statusColor),
      ],
    );
  }

  void _showStatusDetails(
      {required String status, required String masuk, required String pulang}) {
    _showDetailSheet(
      title: 'Detail Status Hari Ini',
      icon: Icons.assignment_turned_in_rounded,
      iconColor: hasOut || hasIn || _approvedLeaveToday != null
          ? AppColors.green
          : AppColors.muted,
      children: [
        _DetailRow(
            icon: Icons.person_pin_rounded,
            label: 'Status Presensi',
            value: status,
            valueColor: hasIn || hasOut || _approvedLeaveToday != null
                ? AppColors.green
                : AppColors.orange),
        _DetailRow(icon: Icons.login_rounded, label: 'Jam Masuk', value: masuk),
        _DetailRow(
            icon: Icons.logout_rounded, label: 'Jam Pulang', value: pulang),
        _DetailRow(
            icon: Icons.notes_rounded,
            label: 'Keterangan',
            value: _statusMessage(status)),
        _DetailRow(
            icon: Icons.location_on_rounded,
            label: 'Lokasi / Jarak',
            value: _distance == null
                ? 'Belum tersedia'
                : '${_distance!.round()} m dari kantor'),
        const _DetailRow(
            icon: Icons.camera_alt_rounded,
            label: 'Metode',
            value: 'Selfie + GPS'),
      ],
    );
  }

  void _showDetailSheet(
      {required String title,
      required IconData icon,
      required Color iconColor,
      required List<Widget> children}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final maxHeight = MediaQuery.sizeOf(context).height * .88;
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: .14),
                    blurRadius: 28,
                    offset: const Offset(0, -4))
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.line,
                          borderRadius: BorderRadius.circular(99))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: .11),
                              borderRadius: BorderRadius.circular(16)),
                          child: Icon(icon, color: iconColor)),
                      const SizedBox(width: 13),
                      Expanded(
                          child: Text(title,
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900))),
                      IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...children,
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: .10),
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      child: const Text('Tutup',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _scheduleText(String? value, {String fallback = '-'}) {
    final text = (value ?? '').trim();
    return text.isEmpty ? fallback : text;
  }

  String _groupLabel() {
    final group = widget.session.groupName.trim();
    final department = widget.session.departmentName.trim();
    final sub = widget.session.subDepartmentName.trim();
    final parts = <String>[
      if (group.isNotEmpty) group,
      if (department.isNotEmpty) department,
      if (sub.isNotEmpty) sub
    ];
    if (parts.isEmpty)
      return widget.session.officeName.isEmpty
          ? '-'
          : widget.session.officeName;
    return parts.join(' — ');
  }

  String _workTime(DailySchedule? schedule) {
    if (schedule == null || !schedule.isWorkday) return '-';
    final start = schedule.workStart.isNotEmpty
        ? schedule.workStart
        : schedule.checkInStart;
    final end =
        schedule.workEnd.isNotEmpty ? schedule.workEnd : schedule.checkOutEnd;
    if (start.isEmpty && end.isEmpty) return '-';
    return '$start - $end';
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'overtime_schedule':
        return 'Jadwal Lembur';
      case 'user_assignment':
        return 'Penerapan Jadwal User';
      case 'group_assignment':
        return 'Penerapan Jadwal Rutin';
      case 'special_schedule':
        return 'Jadwal Khusus';
      case 'holiday':
        return 'Hari Libur';
      default:
        return source.isEmpty ? '-' : source;
    }
  }

  String _statusMessage(String status) {
    if (_approvedLeaveToday != null)
      return 'Pengajuan sudah disetujui admin. Absen hari ini tidak wajib dilakukan.';
    if (hasOut) return 'Presensi hari ini sudah lengkap.';
    if (hasIn) return 'Silakan lakukan absen pulang.';
    return 'Silakan lakukan absen masuk sesuai jadwal.';
  }

  String _leaveTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'sakit':
        return 'Sakit';
      case 'cuti':
        return 'Cuti';
      default:
        return 'Izin';
    }
  }
}

class _ApprovedLeaveBanner extends StatelessWidget {
  final String type;
  final String reason;

  const _ApprovedLeaveBanner({required this.type, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.green.withValues(alpha: .24))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(15)),
              child:
                  const Icon(Icons.verified_rounded, color: AppColors.green)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$type Disetujui Hari Ini',
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  reason.trim().isEmpty
                      ? 'Absen tidak wajib dilakukan karena pengajuan sudah disetujui admin.'
                      : reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.muted, size: 19)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w800))),
          const SizedBox(width: 12),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: valueColor ?? AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
