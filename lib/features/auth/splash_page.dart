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
  String _message = 'Mem