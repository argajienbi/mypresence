import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/models/app_session.dart';
import '../../../core/utils.dart';

class CompanyLogoAvatar extends StatelessWidget {
  final AppSession session;
  final double size;

  const CompanyLogoAvatar({
    super.key,
    required this.session,
    this.size = 58,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('companies/${session.companyId}').onValue,
      builder: (context, snapshot) {
        final company = asMap(snapshot.data?.snapshot.value);
        final logoUrl = asString(
          company['company_logo_url'],
          asString(company['logo_url']),
        );
        final name = asString(
          company['name'],
          asString(company['company_name'], session.officeName),
        );

        final child = logoUrl.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  logoUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _FallbackLogo(name: name, size: size),
                ),
              )
            : _FallbackLogo(name: name, size: size);

        return Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  final String name;
  final double size;

  const _FallbackLogo({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
          fontSize: 13,
          height: 1.05,
        ),
      ),
    );
  }

  String _initials(String source) {
    final parts = source.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'MY';
    if (parts.length == 1) return parts.first.length <= 3 ? parts.first.toUpperCase() : parts.first.substring(0, 3).toUpperCase();
    return parts.take(2).map((e) => e.substring(0, 1)).join().toUpperCase();
  }
}
