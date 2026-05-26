import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../pages/history/history_page.dart';
import '../pages/home/home_page.dart';
import '../pages/profile/profile_page.dart';

class MyBottomNav extends StatelessWidget {
  final int currentIndex;

  const MyBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Beranda',
            active: currentIndex == 0,
            onTap: () {
              if (currentIndex != 0) {
                Navigator.pushReplacementNamed(context, HomePage.routeName);
              }
            },
          ),
          _NavItem(
            icon: Icons.history_rounded,
            label: 'Riwayat',
            active: currentIndex == 1,
            onTap: () {
              if (currentIndex != 1) {
                Navigator.pushReplacementNamed(context, HistoryPage.routeName);
              }
            },
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Profil',
            active: currentIndex == 2,
            onTap: () {
              if (currentIndex != 2) {
                Navigator.pushReplacementNamed(context, ProfilePage.routeName);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : const Color(0xFF7B8794);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
