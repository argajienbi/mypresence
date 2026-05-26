import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/session/app_session_controller.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import '../home/home_page.dart';

class SplashPage extends StatefulWidget {
  static const routeName = '/';

  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String _message = 'Memuat sesi...';

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    try {
      final auth = AuthService();
      if (auth.currentUser == null) {
        Navigator.pushReplacementNamed(context, LoginPage.routeName);
        return;
      }

      final session = await auth.loadSession();

      if (!mounted) return;
      AppSessionController.instance.setSession(session);
      Navigator.pushReplacementNamed(context, HomePage.routeName);
    } catch (e) {
      setState(() => _message = e.toString().replaceFirst('Exception: ', ''));
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, LoginPage.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Text(
                  'MP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'MYPRESENSI',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Presensi mobile terhubung perusahaan',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              const SizedBox(height: 18),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
