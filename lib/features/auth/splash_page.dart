import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/error_mapper.dart';
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

class _SplashPageState extends State<SplashPage> {
  final AuthService _auth = AuthService();

  String _message = 'Memeriksa sesi...';
  String _error = '';
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    if (!mounted) return;

    final user = _auth.currentUser;
    if (user == null) {
      _goToLogin();
      return;
    }

    setState(() {
      _message = 'Menyiapkan akun...';
      _error = '';
      _showRetry = false;
    });

    try {
      final AppSession session = await _auth.loadSession();

      try {
        await PushNotificationService.registerDeviceToken(session)
            .timeout(const Duration(seconds: 12));
      } catch (e) {
        debugPrint('Gagal register FCM token dari splash: $e');
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainShell(session: session)),
      );
    } catch (e) {
      final message = friendlyError(e);
      debugPrint('Splash bootstrap error: $e');

      if (!mounted) return;

      setState(() {
        _message = 'Gagal menyiapkan sesi.';
        _error = message;
        _showRetry = true;
      });
    }
  }

  void _goToLogin() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _logoutAndLogin() async {
    try {
      await _auth.logout();
    } catch (_) {}

    _goToLogin();
  }

  Future<void> _retry() async {
    setState(() {
      _message = 'Memeriksa ulang sesi...';
      _error = '';
      _showRetry = false;
    });

    await _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEAF8F2),
                Color(0xFFF7FCFA),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .08),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 54,
                        color: Color(0xFF18B765),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'MY PRESENCE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF10211A),
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.7,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF66746E),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (_error.isEmpty)
                      const SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Color(0xFFE2ECE7)),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFFE85D5D),
                              size: 30,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF10211A),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_showRetry) ...[
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _retry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF18B765),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Coba Lagi',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _logoutAndLogin,
                        child: const Text('Keluar dan Login Ulang'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
