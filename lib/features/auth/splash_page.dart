import 'dart:async';
import 'package:flutter/material.dart';

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

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
    _logoScale = Tween<double>(begin: .72, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _controller, curve: const Interval(.08, .86, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, .18), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _bootTimer = Timer(const Duration(milliseconds: 180), _start);
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
      setState(() => _message = 'Memeriksa sesi login...');

      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        try {
          session = await _auth.loadSession().timeout(const Duration(seconds: 6));
        } catch (_) {
          // Offline/network error tidak boleh memaksa logout.
          // Session FirebaseAuth tetap dipertahankan, user diberi tombol retry.
          session = null;
          if (mounted) {
            setState(() {
              _sessionLoadFailed = true;
              _message = 'Tidak ada koneksi atau data sesi belum bisa dimuat.';
            });
          }
        }
      }
    } catch (_) {
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
      await PushNotificationService.registerDeviceToken(resolvedSession).timeout(const Duration(seconds: 5));
    } catch (_) {}

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
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, .025), end: Offset.zero).animate(curved),
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
    _start();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final illustrationWidth = size.width.clamp(320.0, 520.0) * .68;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AuthUi.screenGradient(),
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const AuthHeaderBackground(
                height: 218,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 26, 24, 0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: AuthBrandTitle(),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 118, 24, 24),
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
                              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                              radius: 28,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const MyPresenceLogo(size: 88, textSize: 23),
                                  const SizedBox(height: 14),
                                  SplashIllustration(width: illustrationWidth.clamp(220.0, 300.0)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
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
                          style: const TextStyle(color: AuthUi.muted, fontSize: 13, fontWeight: FontWeight.w800),
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
                              backgroundColor: AuthUi.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        )
                      else
                        const _SplashProgress(),
                      const Spacer(),
                      Text(
                        'Versi 1.2.3',
                        style: TextStyle(color: AuthUi.text.withValues(alpha: .72), fontSize: 12, fontWeight: FontWeight.w700),
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

class _SplashProgress extends StatelessWidget {
  const _SplashProgress();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2100),
      curve: Curves.easeInOutCubic,
      builder: (context, value, _) => Container(
        width: 126,
        height: 7,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(.08, 1),
          child: Container(
            decoration: BoxDecoration(
              color: AuthUi.green,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AuthUi.green.withValues(alpha: .26), blurRadius: 10)],
            ),
          ),
        ),
      ),
    );
  }
}
