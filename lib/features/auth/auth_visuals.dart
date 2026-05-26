import 'package:flutter/material.dart';

class AuthUi {
  static const Color bgTop = Color(0xFFEAF8F2);
  static const Color bgBottom = Color(0xFFF7FCFA);
  static const Color headerGreen = Color(0xFF12975B);
  static const Color green = Color(0xFF18B765);
  static const Color greenDark = Color(0xFF0F7E4D);
  static const Color deepTeal = Color(0xFF146B58);
  static const Color softGreen = Color(0xFFE6F8EF);
  static const Color paleGreen = Color(0xFFF1FBF6);
  static const Color text = Color(0xFF10211A);
  static const Color muted = Color(0xFF66746E);
  static const Color line = Color(0xFFE2ECE7);
  static const String appLogoAsset = 'assets/images/app_logo.png';
  static const String authIllustrationAsset = 'assets/images/auth_illustration.png';

  static BoxDecoration screenGradient() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [bgTop, bgBottom],
      ),
    );
  }

  static List<BoxShadow> softShadow([double opacity = .08]) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: opacity),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }
}

class AuthHeaderBackground extends StatelessWidget {
  final double height;
  final Widget? child;

  const AuthHeaderBackground({
    super.key,
    this.height = 210,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipPath(
            clipper: _AuthHeaderCurveClipper(),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AuthUi.headerGreen, AuthUi.greenDark],
                ),
              ),
            ),
          ),
          Positioned(
            right: -34,
            top: 18,
            child: _SoftCircle(size: 128, opacity: .11),
          ),
          Positioned(
            left: -42,
            top: 72,
            child: _SoftCircle(size: 104, opacity: .09),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _AuthHeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height * .86)
      ..quadraticBezierTo(
        size.width * .50,
        size.height,
        size.width,
        size.height * .86,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SoftCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _SoftCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
      ),
    );
  }
}

class MyPresenceLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final double textSize;
  final Color textColor;

  const MyPresenceLogo({
    super.key,
    this.size = 112,
    this.showText = true,
    this.textSize = 27,
    this.textColor = AuthUi.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * .13),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: AuthUi.softShadow(.12),
          ),
          child: Image.asset(AuthUi.appLogoAsset, fit: BoxFit.contain),
        ),
        if (showText) ...[
          const SizedBox(height: 10),
          Text(
            'MY PRESENCE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: textSize,
              fontWeight: FontWeight.w900,
              letterSpacing: -.7,
            ),
          ),
        ],
      ],
    );
  }
}

class AuthBrandTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool center;

  const AuthBrandTitle({
    super.key,
    this.title = 'MY PRESENCE',
    this.subtitle = 'Aplikasi Presensi Karyawan',
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .86),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class AuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const AuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: .80), width: 1.1),
        boxShadow: AuthUi.softShadow(.09),
      ),
      child: child,
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: AuthUi.text,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(
          color: AuthUi.muted,
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
        prefixIcon: Icon(icon, size: 20, color: AuthUi.deepTeal),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AuthUi.paleGreen,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AuthUi.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AuthUi.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AuthUi.green, width: 1.4),
        ),
      ),
    );
  }
}

class GreenPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const GreenPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AuthUi.green,
          disabledBackgroundColor: AuthUi.green.withValues(alpha: .52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
              ),
      ),
    );
  }
}

class SecondaryOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SecondaryOutlineButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AuthUi.deepTeal,
          side: const BorderSide(color: AuthUi.deepTeal, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class SplashIllustration extends StatelessWidget {
  final double width;

  const SplashIllustration({super.key, this.width = 250});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AuthUi.authIllustrationAsset,
      width: width,
      fit: BoxFit.contain,
    );
  }
}

class AuthPersonIllustration extends StatelessWidget {
  final double width;

  const AuthPersonIllustration({super.key, this.width = 150});

  @override
  Widget build(BuildContext context) {
    return SplashIllustration(width: width);
  }
}

class MiniSupportIllustration extends StatelessWidget {
  const MiniSupportIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class AuthErrorBanner extends StatelessWidget {
  final String message;

  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD8D8)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFD93025),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
