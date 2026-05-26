import 'package:flutter/material.dart';
import '../pages/attendance/camera_presence_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/history/history_page.dart';
import '../pages/home/home_page.dart';
import '../pages/leave/leave_form_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/splash/splash_page.dart';
import 'theme.dart';

class MyPresensiApp extends StatelessWidget {
  const MyPresensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MYPRESENSI',
        theme: AppTheme.light(),
        initialRoute: SplashPage.routeName,
        routes: {
          SplashPage.routeName: (_) => const SplashPage(),
          LoginPage.routeName: (_) => const LoginPage(),
          RegisterPage.routeName: (_) => const RegisterPage(),
          HomePage.routeName: (_) => const HomePage(),
          HistoryPage.routeName: (_) => const HistoryPage(),
          ProfilePage.routeName: (_) => const ProfilePage(),
          CameraPresencePage.routeName: (_) => const CameraPresencePage(),
          LeaveFormPage.routeName: (_) => const LeaveFormPage(),
        },
      );
  }
}
