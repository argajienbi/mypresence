import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  static const routeName = '/home';
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Home legacy route. Use features/home/main_shell.dart')));
}
