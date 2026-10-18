import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_session.dart';
import '../../services/auth_service.dart';
import '../../services/push_notification_service.dart';
import '../home/main_shell.dart';
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
    final bottomInset = media.padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF06337A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
                Color(0xFF06337A),
              ],
              stops: [0.0, 0.7, 1.0],
            ),
          ),
          child: Stack(
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
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    // Logo + judul (mockup 05)
                    FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slide,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 104,
                                height: 104,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: .18),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text('📍',
                                      style: TextStyle(fontSize: 52)),
                                ),
                              ),
                              const SizedBox(height: 22),
                              const Text(
                                'MyPresence',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Absensi cerdas untuk tim Anda',
                                style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: .85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Status / pesan
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 360),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: Text(
                        _sessionLoadFailed
                            ? 'Tidak Ada Koneksi Internet\nAnda masih login, tetapi data terbaru belum bisa dimuat.'
                            : _message,
                        key: ValueKey('$_message-$_sessionLoadFailed'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .94),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_sessionLoadFailed)
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
                      )
                    else
                      const _BlinkingDots(),
                    const Spacer(flex: 4),
                    // Footer versi (mockup 05)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8 + bottomInset),
                      child: Text(
                        'v2.4.1 • PT FMI',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .6),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: bottomInset),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animasi loading 3 titik berkedip sesuai mockup 05.
class _BlinkingDots extends StatefulWidget {
  const _BlinkingDots();

  @override
  State<_BlinkingDots> createState() => _BlinkingDotsState();
}

class _BlinkingDotsState extends State<_BlinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Setiap titik berkedip bergantian dengan jeda 0.2
            final phase = (_controller.value + index * 0.2) % 1.0;
            final opacity = phase < 0.5
                ? 0.35 + (phase / 0.5) * 0.65
                : 1.0 - ((phase - 0.5) / 0.5) * 0.65;
            return Container(
              width: 9,
              height: 9,
              margin: EdgeInsets.only(left: index == 0 ? 0 : 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: opacity.clamp(0.35, 1.0)),
              ),
            );
          },
        );
      }),
    );
  }
}
