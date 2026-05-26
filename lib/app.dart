import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'core/app_navigator.dart';
import 'features/auth/splash_page.dart';

class MyPresensiApp extends StatelessWidget {
  const MyPresensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MYPRESNSI',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: AppTheme.light(),
      home: const SplashPage(),
    );
  }
}
