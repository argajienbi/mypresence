import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_session.dart';
import '../../services/auth_service.dart';
import '../../services/push_notification_service.dart';
import '../home/main_shell.dart';
import 'auth_visuals.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();

  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  String _message = 'Menyiapkan aplikasi...';
  bool _navigated = false;
  bool _sessionLoadFailed = false;
  Timer? _bootTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _logoScale = Tween<double>(begin: .72, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.08, .86, curve: Curves.easeOut),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, .18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    _bootTimer = Timer(const Duration(milliseconds: 180), () {
      unawaited(_start());
    });
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final startedAt = DateTime.now();

    AppSession? session;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 450));

      if (!mounted) return;

      setState(() {
        _message = 'Memeriksa sesi login...';
      });

      final currentUser = _auth.currentUser;

      if (currentUser != null) {
        try {
          session = await _auth.loadSession().timeout(
                const Duration(seconds: 6),
              );
        } catch (e) {
          debugPrint('Gagal load session dari splash: $e');

          session = null;

          if (mounted) {
            setState(() {
              _sessionLoadFailed = true;
              _message = 'Tidak ada koneksi atau data sesi belum bisa dimuat.';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Splash start error: $e');
      session = null;
    }

    final elapsed = DateTime.now().difference(startedAt);
    final remain = const Duration(milliseconds: 2300) - elapsed;

    if (remain > Duration.zero) {
      await Future<void>.delayed(remain);
    }

    if (!mounted) return;

    final resolvedSession = session;

    if (resolvedSession == null) {
      if (_auth.currentUser != null && _sessionLoadFailed) {
        return;
      }

      await _safeNavigate(() => const LoginPage());
      return;
    }

    try {
      await PushNotificationService.registerDeviceToken(resolvedSession)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Gagal register token notifikasi dari splash: $e');
    }

    unawaited(
      PushNotificationService.refreshCurrentTokenStatus(resolvedSession),
    );

    await _safeNavigate(() => MainShell(session: resolvedSession));
  }

  Future<void> _safeNavigate(Widget Function() builder) async {
    if (_navigated || !mounted) return;

    _navigated = true;

    await Future<void>.delayed(Duration.zero);

    if (!mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);

    navigator.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => builder(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .025),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: .985, end: 1).animate(curved),
                child: child,
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
      (_) => false,
    );
  }

  void _retrySessionLoad() {
    if (_navigated) return;

    setState(() {
      _sessionLoadFailed = false;
      _message = 'Mencoba memuat ulang sesi...';
    });

    unawaited(_start());
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final topInset = media.padding.top;
    final bottomInset = media.padding.bottom;
    final illustrationWidth = size.width.clamp(320.0, 520.0) * .68;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.primaryDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            // Mockup: gradient teal gelap (#0b2b33) -> teal (#0b7a8c).
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDark,
                AppColors.primary,
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Dekorasi lingkaran lembut (mockup 05)
              Positioned(
                right: -70,
                top: -50,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .06),
                  ),
                ),
              ),
              Positioned(
                left: -60,
                bottom: 120,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .05),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    topInset + 48,
                    24,
                    24 + bottomInset,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FadeTransition(
                        opacity: _fade,
                        child: SlideTransition(
                          position: _slide,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: AuthCard(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                18,
                                18,
                                18,
                              ),
                              radius: 10,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const MyPresenceLogo(
                                    size: 88,
                                    textSize: 23,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Presensi mobile terhubung perusahaan',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  SplashIllustration(
                                    width: illustrationWidth.clamp(
                                      220.0,
                                      300.0,
                                    ),
                                  ),
                                  // Progress + pesan muat di dalam kartu (mockup).
                                  if (!_sessionLoadFailed) ...[
                                    const SizedBox(height: 20),
                                    const _SplashProgress(),
                                    const SizedBox(height: 10),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 360,
                                      ),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      child: Text(
                                        _message,
                                        key: ValueKey(_message),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Pesan muat + progress kini di dalam kartu; di bawah
                      // kartu hanya tampil saat sesi gagal dimuat.
                      if (_sessionLoadFailed) ...[
                        const SizedBox(height: 18),
                        Text(
                          'Tidak Ada Koneksi Internet\nAnda masih login, tetapi data terbaru belum bisa dimuat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: .18),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 46,
                          child: FilledButton.icon(
                            onPressed: _retrySessionLoad,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Coba Lagi'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      const Text(
                        'v2.4.1 • PT FMI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

/// Progress bar di dalam kartu splash (mockup): trek abu muda, isi teal.
class _SplashProgress extends StatelessWidget {
  const _SplashProgress();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2100),
      curve: Curves.easeInOutCubic,
      builder: (context, value, _) => Container(
        width: 200,
        height: 6,
        decoration: BoxDecoration(
          color: AppColors.line,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(.08, 1),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}
