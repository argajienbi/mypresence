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
import '../schedule/schedule_detail_page.dart';
import 'widgets/clock_attendance_card.dart';
import 'widgets/home_announcement_card.dart';
import 'widgets/home_quick_menu_horizontal.dart';
import 'widgets/home_sticky_profile_header.dart';
import 'widgets/radius_card.dart';
import 'widgets/status_detail_sheet.dart';

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
      const Duration(minutes: 5),
      (_) => _loadSchedule(notifyChange: true),
    );
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
      final type = _leaveTypeLabel((leave['type'] ?? leave['leave_type'] ?? '').toString());
      AppToast.info(
        context,
        'Hari ini pengajuan $type Anda sudah disetujui. Absen tidak wajib dilakukan.',
      );
      return;
    }

    if (_loadingSchedule) {
      AppToast.info(context, 'Jadwal kerja masih dimuat. Coba beberapa saat lagi.');
      return;
    }

    DailySchedule? schedule = _schedule;
    try {
      schedule ??= await _scheduleService.resolveToday(widget.session);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Jadwal kerja belum bisa dibaca. Coba muat ulang aplikasi.');
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
      final distanceText = _distance == null ? '' : ' (${_distance!.toStringAsFixed(0)} m dari kantor)';
      AppToast.error(context, 'Anda berada di luar radius kantor$distanceText.');
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

  void _showScheduleDetails() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScheduleDetailPage(
        session: widget.session,
        scheduleService: _scheduleService,
        initialDate: DateTime.now(),
        initialSchedule: _schedule,
      ),
    ));
  }

  void _showStatusDetails({
    required String status,
    required String masuk,
    required String pulang,
  }) {
    showStatusDetailSheet(
      context: context,
      data: StatusDetailData(
        status: status,
        masuk: masuk,
        pulang: pulang,
        message: _statusMessage(status),
        distanceMeter: _distance,
        insideRadius: _insideRadius,
        hasIn: hasIn,
        hasOut: hasOut,
        hasApprovedLeave: _approvedLeaveToday != null,
      ),
    );
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
          Positioned.fill(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 188, 18, 128),
              children: [
                if (_approvedLeaveToday != null) ...[
                  _ApprovedLeaveBanner(
                    type: _leaveTypeLabel(
                      (_approvedLeaveToday!['type'] ??
                              _approvedLeaveToday!['leave_type'] ??
                              '')
                          .toString(),
                    ),
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
                const SizedBox(height: 14),
                ClockAttendanceCard(
                  nextAction: nextAction,
                  insideRadius: _insideRadius,
                  hasIn: hasIn,
                  hasOut: hasOut,
                  onPressed: _openAttendance,
                ),
                const SizedBox(height: 16),
                HomeQuickMenuHorizontal(
                  onStatus: () => _showStatusDetails(
                    status: status,
                    masuk: masuk,
                    pulang: pulang,
                  ),
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: StreamBuilder<List<AppNotification>>(
              stream: _notificationService.watchFirestoreInbox(widget.session),
              builder: (context, firestoreSnapshot) {
                final firestoreItems = firestoreSnapshot.data ?? const <AppNotification>[];
                return StreamBuilder<List<AppNotification>>(
                  stream: _notificationService.watchRtdbFallback(widget.session),
                  builder: (context, rtdbSnapshot) {
                    final rtdbItems = rtdbSnapshot.data ?? const <AppNotification>[];
                    final allItems = _notificationService.mergeInbox(firestoreItems, rtdbItems);
                    final unreadCount = allItems
                        .where((item) => !item.read && _isImportantNotification(item.refType))
                        .length;

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
    final value = refType.toLowerCase();

    if (value.contains('announcement') || value.contains('pengumuman')) {
      return false;
    }

    return value.contains('approval') ||
        value.contains('leave') ||
        value.contains('izin') ||
        value.contains('cuti') ||
        value.contains('sakit') ||
        value.contains('schedule') ||
        value.contains('jadwal') ||
        value.contains('attendance') ||
        value.contains('presensi') ||
        value.contains('system');
  }

  String _workTime(DailySchedule? schedule) {
    if (schedule == null || !schedule.isWorkday) return '-';
    final start = schedule.workStart.isNotEmpty ? schedule.workStart : schedule.checkInStart;
    final end = schedule.workEnd.isNotEmpty ? schedule.workEnd : schedule.checkOutEnd;
    if (start.isEmpty && end.isEmpty) return '-';
    return '$start - $end';
  }

  String _statusMessage(String status) {
    if (_approvedLeaveToday != null) {
      return 'Pengajuan sudah disetujui admin. Absen hari ini tidak wajib dilakukan.';
    }
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
        border: Border.all(color: AppColors.green.withValues(alpha: .24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.verified_rounded, color: AppColors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$type Disetujui Hari Ini',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
