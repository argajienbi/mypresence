import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
import '../../services/notification_service.dart';
import '../../services/push_notification_service.dart';
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
import 'widgets/location_detail_sheet.dart';
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
  final NotificationService _deliveryService = NotificationService();

  Timer? _timer;
  Timer? _schedulePollTimer;
  String _date = AppDate.dayDate(DateTime.now());
  double? _distance;
  double? _userLat;
  double? _userLng;
  bool _insideRadius = false;
  bool _loadingLocation = true;
  Map<String, dynamic>? _today;
  Map<String, dynamic>? _yesterday;
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
    unawaited(PushNotificationService.refreshCurrentTokenStatus(widget.session));
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
      _loadYesterday(),
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

  Future<void> _loadYesterday() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final data = await _attendance.attendanceForDate(widget.session, yesterday);
      if (mounted) setState(() => _yesterday = data);
    } catch (_) {
      // Abaikan — tiket tetap tampil dengan fallback.
    }
  }

  Future<void> _loadSchedule({bool notifyChange = false, int retryCount = 0}) async {
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
      // Retry otomatis jika hasil kosong (waktu kosong) — samakan dengan Detail Jadwal.
      if (_isScheduleEmpty(data) && retryCount < 2) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        final retry = await _scheduleService.resolveToday(widget.session);
        if (!mounted) return;
        if (!_isScheduleEmpty(retry)) {
          setState(() {
            _schedule = retry;
            _lastScheduleFingerprint = _scheduleFingerprint(retry);
          });
        }
      }
      await _scheduleAttendanceReminders();
      if (changed) await _showScheduleChangedNotification(data);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _schedule = null;
        _loadingSchedule = false;
      });
      // Retry maksimal 2x jika gagal total.
      if (retryCount < 2) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _loadSchedule(notifyChange: notifyChange, retryCount: retryCount + 1);
      }
    }
  }

  /// Cek apakah jadwal kosong (semua field waktu kosong) — perlu retry.
  bool _isScheduleEmpty(dynamic schedule) {
    if (schedule == null) return true;
    try {
      final s = schedule as dynamic;
      return (s.workStart as String).isEmpty &&
          (s.workEnd as String).isEmpty &&
          (s.checkInStart as String).isEmpty;
    } catch (_) {
      return false;
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
    await AttendanceReminderService.scheduleToday(
      session: widget.session,
      schedule: _schedule,
      hasIn: hasIn,
      hasOut: hasOut,
      hasApprovedLeave: _approvedLeaveToday != null,
    );
  }

  Future<void> _showScheduleChangedNotification(DailySchedule schedule) async {
    final body = schedule.isWorkday
        ? 'Jadwal hari ini: ${_workTime(schedule)}.'
        : schedule.message;
    final now = DateTime.now();
    final notificationId = _scheduleNotificationId(schedule, now);
    final refId = schedule.assignmentId.isNotEmpty
        ? schedule.assignmentId
        : schedule.overtimeScheduleId.isNotEmpty
            ? schedule.overtimeScheduleId
            : schedule.timetableId.isNotEmpty
                ? schedule.timetableId
                : AppDate.dateKey(now);

    final payload = <String, dynamic>{
      'notification_id': notificationId,
      'id': notificationId,
      'inbox_id': notificationId,
      'company_id': widget.session.companyId,
      'uid': widget.session.uid,
      'title': 'Jadwal Kerja Diperbarui',
      'body': body,
      'message': body,
      'type': 'schedule_update',
      'ref_type': 'schedule',
      'ref_id': refId,
      'related_id': refId,
      'sender_uid': 'system',
      'sender_name': 'Sistem',
      'sender_role': 'system',
      'created_at': now.millisecondsSinceEpoch,
      'created_date': AppDate.dateKey(now),
      'created_time': AppDate.time(now),
      'schedule_source': schedule.source,
      'schedule_fingerprint': _scheduleFingerprint(schedule),
      'schedule_ready': schedule.scheduleReady,
      'active': true,
      'read': false,
      'is_read': false,
    };

    await _deliveryService.upsertPayload(
      session: widget.session,
      payload: payload,
    );

    await LocalNotificationService.show(
      id: notificationId.hashCode.abs().remainder(2147483647),
      title: 'Jadwal Kerja Diperbarui',
      body: body,
      payload: payload,
    );
  }

  String _scheduleNotificationId(DailySchedule schedule, DateTime now) {
    final fingerprint = _scheduleFingerprint(schedule);
    final seed = [
      widget.session.companyId,
      widget.session.uid,
      AppDate.dateKey(now),
      fingerprint,
    ].join('|');
    final slug = seed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return 'schedule_update_$slug';
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

  /// Label info "Terakhir" untuk kartu tiket.
  String? get _lastLabel {
    if (hasOut) return null; // kartu pakai fallback 'Pulang $pulang'
    if (hasIn) return null; // kartu pakai fallback 'Masuk $masuk'
    // Belum absen hari ini — tampilkan data kemarin (mockup).
    final y = _yesterday;
    if (y != null) {
      final masuk = y['masuk'];
      final pulang = y['pulang'];
      final masukTime = masuk is Map ? (masuk['time'] ?? '').toString() : '';
      final pulangTime = pulang is Map ? (pulang['time'] ?? '').toString() : '';
      if (pulangTime.isNotEmpty) return 'Kemarin $pulangTime';
      if (masukTime.isNotEmpty) return 'Kemarin $masukTime';
    }
    return null; // kartu tampil '-'
  }

  /// Label info "Berikutnya" untuk kartu tiket (dari jadwal).
  String get _nextLabel {
    final s = _schedule;
    final ws = s == null
        ? ''
        : (s.workStart.isNotEmpty ? s.workStart : s.checkInStart);
    final we = s == null
        ? ''
        : (s.workEnd.isNotEmpty ? s.workEnd : s.checkOutEnd);
    String t(String v) => v.isEmpty ? '--:--' : v;
    if (!hasIn) return 'Masuk ${t(ws)}';
    if (!hasOut) return 'Pulang ${t(we)}';
    return 'Besok ${t(ws)}';
  }

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
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => ScheduleDetailPage(
        session: widget.session,
        scheduleService: _scheduleService,
        initialDate: DateTime.now(),
        initialSchedule: _schedule,
      ),
    ))
        .then((_) {
      // Refresh jadwal saat kembali — samakan tiket dengan halaman detail.
      if (mounted) _loadSchedule(notifyChange: true);
    });
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // Header biru: collapse + parallax saat scroll (mockup).
          SliverAppBar(
            expandedHeight: 176,
            collapsedHeight: 0,
            toolbarHeight: 0,
            pinned: false,
            floating: false,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: StreamBuilder<List<AppNotification>>(
                stream:
                    _notificationService.watchFirestoreInbox(widget.session),
                builder: (context, firestoreSnapshot) {
                  final firestoreItems =
                      firestoreSnapshot.data ?? const <AppNotification>[];
                  return StreamBuilder<List<AppNotification>>(
                    stream:
                        _notificationService.watchRtdbFallback(widget.session),
                    builder: (context, rtdbSnapshot) {
                      final rtdbItems =
                          rtdbSnapshot.data ?? const <AppNotification>[];
                      final allItems = _notificationService.mergeInbox(
                          firestoreItems, rtdbItems);
                      final unreadCount =
                          allItems.where((item) => !item.read).length;

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
          ),
          // Kartu lokasi: sticky di atas saat header menghilang (mockup).
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyCardDelegate(
              height: 128,
              topPadding: MediaQuery.of(context).padding.top,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: RadiusCard(
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
                  onTap: () => unawaited(
                    showLocationDetailSheet(
                      context: context,
                      data: LocationDetailData(
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
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  ClockAttendanceCard(
                    nextAction: nextAction,
                    insideRadius: _insideRadius,
                    hasIn: hasIn,
                    hasOut: hasOut,
                    checkInTime: masuk,
                    checkOutTime: pulang,
                    lastLabel: _lastLabel,
                    nextLabel: _nextLabel,
                    onPressed: _openAttendance,
                  ),
                  const SizedBox(height: 14),
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
          ),
        ],
      ),
      ),
    );
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

/// Delegate untuk kartu lokasi yang sticky di atas (mockup: berhenti di
/// header, tidak ikut menghilang saat scroll).
class _StickyCardDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  final double topPadding;

  const _StickyCardDelegate({
    required this.child,
    required this.height,
    this.topPadding = 0,
  });

  @override
  double get minExtent => height + topPadding;

  @override
  double get maxExtent => height + topPadding;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Area status bar diisi biru agar menyatu dengan banner kartu
    // (tidak ada gap visual; ikon status bar putih tetap terbaca).
    return Container(
      color: AppColors.bg,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            height: topPadding,
            color: AppColors.primary,
          ),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyCardDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.height != height ||
        oldDelegate.topPadding != topPadding;
  }
}
