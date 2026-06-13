import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_session.dart';
import '../../core/session/app_session_controller.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/request_status_service.dart';
import '../../services/schedule_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/sticky_curve_header.dart';
import '../requests/request_status_page.dart';
import '../auth/login_page.dart';
import '../announcements/announcements_page.dart';
import '../company_webview/company_webview_page.dart';
import 'edit_profile_page.dart';
import 'employee_qr_page.dart';
import 'help_center_page.dart';
import 'terms_page.dart';

class ProfilePage extends StatefulWidget {
  final AppSession session;
  final ValueChanged<AppSession>? onSessionUpdated;

  const ProfilePage({
    super.key,
    required this.session,
    this.onSessionUpdated,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  final RequestStatusService _requestStatusService = RequestStatusService();
  bool _uploading = false;
  late final Future<int> _pendingRequestsFuture;
  late String _photoUrl;

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.session.photoUrl;
    _pendingRequestsFuture =
        _requestStatusService.countPendingRequests(widget.session);
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.photoUrl != widget.session.photoUrl) {
      _photoUrl = widget.session.photoUrl;
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showAppConfirmationDialog(
      context: context,
      title: 'Keluar dari Akun?',
      message:
          'Anda akan keluar dari akun ini. Pastikan semua data presensi sudah tersimpan.',
      confirmLabel: 'Keluar',
      cancelLabel: 'Batal',
      icon: Icons.logout_rounded,
      accentColor: AppColors.red,
    );
    if (confirm != true) return;

    try {
      await AuthService().logoutWithSession(widget.session);
    } catch (_) {
      // Tetap arahkan ke login agar UI tidak blank meskipun signOut gagal sesaat.
    }

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    Navigator.of(context).pop();
    setState(() => _uploading = true);
    try {
      final result = await _profileService.pickUploadAndSavePhoto(
          session: widget.session, source: source);
      if (!mounted) return;
      if (result != null) {
        final refreshedSession = await _refreshSessionAfterPhotoUpload(result);
        if (!mounted) return;
        setState(() => _photoUrl = refreshedSession.photoUrl);
        AppSessionController.instance.setSession(refreshedSession);
        widget.onSessionUpdated?.call(refreshedSession);
        AppToast.success(context, 'Foto profil berhasil diperbarui.');
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<AppSession> _refreshSessionAfterPhotoUpload(
      ProfilePhotoResult result) async {
    try {
      return await AuthService().loadSession();
    } catch (_) {
      return widget.session.copyWith(
        photoUrl: result.photoUrl,
        photoPath: result.photoPath,
      );
    }
  }

  void _showPhotoSource() {
    showAppBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Perbarui Foto Profil',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text)),
            const SizedBox(height: 14),
            _SheetOption(
                icon: Icons.photo_camera_rounded,
                title: 'Ambil dari Kamera',
                onTap: () => _pickPhoto(ImageSource.camera)),
            _SheetOption(
                icon: Icons.photo_library_rounded,
                title: 'Pilih dari Galeri',
                onTap: () => _pickPhoto(ImageSource.gallery)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLoadingOverlay(
      visible: _uploading,
      message: 'Mengunggah foto profil...',
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            const StickyCurveHeader(
              title: 'Profil',
              subtitle: 'Identitas dan pengaturan akun',
              icon: Icons.person_rounded,
              height: 108,
            ),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 96),
                children: [
                  _ProfileIdentityCard(
                    session: widget.session,
                    photoUrl: _photoUrl,
                    onPhotoTap: _showPhotoSource,
                  ),
                  const SizedBox(height: 14),
                  const _NotificationPermissionBanner(),
                  const SizedBox(height: 14),
                  const _SectionTitle('Informasi Kerja'),
                  const SizedBox(height: 7),
                  AppCard(
                    padding: EdgeInsets.zero,
                    radius: 22,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Column(
                        children: [
                          _InfoTile(
                            icon: Icons.business_rounded,
                            title: 'Kantor',
                            value: widget.session.officeName.isEmpty
                                ? '-'
                                : widget.session.officeName,
                          ),
                          _InfoTile(
                            icon: Icons.groups_rounded,
                            title: 'Grup',
                            value: widget.session.groupName.isEmpty
                                ? '-'
                                : widget.session.groupName,
                          ),
                          FutureBuilder<DailySchedule>(
                            future:
                                ScheduleService().resolveToday(widget.session),
                            builder: (context, snapshot) {
                              final value = snapshot.hasData
                                  ? snapshot.data!.periodLabel
                                  : 'Memuat jadwal...';
                              return _InfoTile(
                                icon: Icons.event_available_rounded,
                                title: 'Jadwal Aktif',
                                value: value,
                                showDivider: false,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _SectionTitle('Pengaturan Akun'),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    radius: 22,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Column(
                        children: [
                          _MenuTile(
                            icon: Icons.person_outline,
                            title: 'Data Pribadi',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      EditProfilePage(session: widget.session)),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.badge_outlined,
                            title: 'ID / QR Karyawan',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => EmployeeQrPage(
                                      session: widget.session,
                                      photoUrl: _displayPhotoUrl(
                                        _photoUrl,
                                        widget.session.photoPath,
                                      ))),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.assignment_turned_in_outlined,
                            title: 'Status Pengajuan',
                            trailing: FutureBuilder<int>(
                              future: _pendingRequestsFuture,
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                if (snapshot.connectionState ==
                                        ConnectionState.waiting ||
                                    count <= 0) {
                                  return const SizedBox.shrink();
                                }
                                return Container(
                                  constraints: const BoxConstraints(
                                      minWidth: 28, minHeight: 28),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.orange.withValues(alpha: .14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    count > 99 ? '99+' : '$count',
                                    style: const TextStyle(
                                      color: AppColors.orange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                );
                              },
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => RequestStatusPage(
                                      session: widget.session)),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.campaign_outlined,
                            title: 'Pengumuman',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => AnnouncementsPage(
                                      session: widget.session)),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.public_rounded,
                            title: 'Website Perusahaan',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => CompanyWebViewPage(
                                      session: widget.session)),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.help_outline,
                            title: 'Pusat Bantuan',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      HelpCenterPage(session: widget.session)),
                            ),
                          ),
                          _MenuTile(
                            icon: Icons.description_outlined,
                            title: 'Syarat & Ketentuan',
                            showDivider: false,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      TermsPage(session: widget.session)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _SectionTitle('Tentang Aplikasi'),
                  const SizedBox(height: 8),
                  const AppCard(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    radius: 22,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.muted, size: 21),
                        SizedBox(width: 12),
                        Text(
                          'Versi 1.0.0',
                          style: TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _logout(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.line),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                            color: AppColors.red, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  final AppSession session;
  final String photoUrl;
  final VoidCallback onPhotoTap;

  const _ProfileIdentityCard(
      {required this.session,
      required this.photoUrl,
      required this.onPhotoTap});

  @override
  Widget build(BuildContext context) {
    final initial = session.displayName.isEmpty
        ? 'MP'
        : session.displayName.trim()[0].toUpperCase();
    final displayPhotoUrl = _displayPhotoUrl(photoUrl, session.photoPath);
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 22,
      child: Row(
        children: [
          GestureDetector(
            onTap: onPhotoTap,
            child: Stack(
              children: [
                CircleAvatar(
                  key: ValueKey(displayPhotoUrl),
                  radius: 36,
                  backgroundColor: AppColors.primary,
                  backgroundImage: displayPhotoUrl.isNotEmpty
                      ? NetworkImage(displayPhotoUrl)
                      : null,
                  child: displayPhotoUrl.isEmpty
                      ? Text(initial,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900))
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 27,
                    height: 27,
                    decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3)),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text)),
                const SizedBox(height: 6),
                Text('NIP: ${session.nip.isEmpty ? '-' : session.nip}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(session.position,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(session.officeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _displayPhotoUrl(String photoUrl, String photoPath) {
  final value = photoUrl.trim();
  if (value.isEmpty) return '';
  final cacheKey = photoPath.trim().isEmpty ? value : photoPath.trim();
  final separator = value.contains('?') ? '&' : '?';
  return '$value${separator}v=${Uri.encodeComponent(cacheKey)}';
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.text));
  }
}

class _ProfileTileDivider extends StatelessWidget {
  const _ProfileTileDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 68, right: 14),
      child: Container(
        height: 1,
        color: AppColors.line.withValues(alpha: .55),
      ),
    );
  }
}

class _ProfileIconBox extends StatelessWidget {
  final IconData icon;

  const _ProfileIconBox(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool showDivider;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _ProfileIconBox(icon),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider) const _ProfileTileDivider(),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool showDivider;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 58,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  _ProfileIconBox(icon),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 10),
                    trailing!,
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.muted, size: 22),
                  ] else
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.muted, size: 22),
                ],
              ),
            ),
          ),
        ),
        if (showDivider) const _ProfileTileDivider(),
      ],
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SheetOption(
      {required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
          backgroundColor: AppColors.header,
          child: Icon(icon, color: AppColors.primary)),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w900, color: AppColors.text)),
    );
  }
}

class _NotificationPermissionBanner extends StatelessWidget {
  const _NotificationPermissionBanner();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NotificationSettings>(
      future: FirebaseMessaging.instance.getNotificationSettings(),
      builder: (context, snapshot) {
        final denied =
            snapshot.data?.authorizationStatus == AuthorizationStatus.denied;
        if (!denied) return const SizedBox.shrink();

        return AppCard(
          padding: const EdgeInsets.all(16),
          radius: 22,
          color: AppColors.orange.withValues(alpha: .08),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_off_outlined,
                  color: AppColors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifikasi belum aktif',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Aktifkan izin notifikasi agar reminder absen dan status pengajuan muncul di status bar.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await PushNotificationService.openNotificationSettings();
                      },
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: const Text('Buka Pengaturan Notifikasi'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
