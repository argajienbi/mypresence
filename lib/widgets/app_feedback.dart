import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class AppToast {
  static void success(BuildContext context, String message) {
    _show(context, message, AppColors.green, Icons.check_circle_rounded);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, AppColors.red, Icons.error_rounded);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, AppColors.primary, Icons.info_rounded);
  }

  static void _show(
      BuildContext context, String message, Color color, IconData icon) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          elevation: 8,
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class AppLoadingOverlay extends StatelessWidget {
  final bool visible;
  final String message;
  final Widget child;

  const AppLoadingOverlay({
    super.key,
    required this.visible,
    required this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (visible)
          Positioned.fill(
            child: AbsorbPointer(
              child: Container(
                color: Colors.black.withValues(alpha: 0.26),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.92, end: 1),
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Container(
                      width: 230,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: .18),
                              blurRadius: 22,
                              offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _PulseLoader(),
                          const SizedBox(height: 18),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w900,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PulseLoader extends StatefulWidget {
  const _PulseLoader();
  @override
  State<_PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<_PulseLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final size = 54 + (_controller.value * 10);
        return Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: const Icon(Icons.sync_rounded,
                color: AppColors.primary, size: 28),
          ),
        );
      },
    );
  }
}

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool dismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 32, end: 0),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) =>
            Transform.translate(offset: Offset(0, value), child: child),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: .18),
                  blurRadius: 22,
                  offset: const Offset(0, 10))
            ],
          ),
          child: child,
        ),
      );
    },
  );
}
