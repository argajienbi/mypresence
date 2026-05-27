import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../core/models/app_notification.dart';
import '../../core/models/app_session.dart';
import '../../services/app_notification_service.dart';
import '../../services/notification_router.dart';
import '../../services/push_notification_service.dart';
import '../history/history_page.dart';
import '../profile/profile_page.dart';
import 'home_page.dart';

class MainShell extends StatefulWidget {
  final AppSession session;
  final int initialIndex;
  final bool showScheduleOnOpen;

  const MainShell({
    super.key,
    required this.session,
    this.initialIndex = 1,
    this.showScheduleOnOpen = false,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;
  late bool _showScheduleOnOpen;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 2);
    _showScheduleOnOpen = widget.showScheduleOnOpen;
    PushNotificationService.onPayloadReceived = _handlePushPayload;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final payload = PushNotificationService.consumePendingPayload();
      if (payload.isNotEmpty) _handlePushPayload(payload);
    });

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    if (PushNotificationService.onPayloadReceived == _handlePushPayload) {
      PushNotificationService.onPayloadReceived = null;
    }
    super.dispose();
  }

  void _handlePushPayload(Map<String, dynamic> payload) {
    if (!mounted || payload.isEmpty) return;
    AppNotificationService().markPayloadAsRead(widget.session, payload);
    if (!mounted) return;
    NotificationRouter.openFromPayload(context, widget.session, payload);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HistoryPage(session: widget.session),
      HomePage(
        session: widget.session,
        showScheduleOnOpen: _showScheduleOnOpen,
        onScheduleShown: () {
          if (_showScheduleOnOpen) setState(() => _showScheduleOnOpen = false);
        },
      ),
      ProfilePage(session: widget.session),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        reverseDuration: const Duration(milliseconds: 160),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey<int>(_index),
          child: pages[_index],
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 72,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withValues(alpha: .14),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: selected ? AppColors.primary : AppColors.muted,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? AppColors.primary : AppColors.muted,
              size: selected ? 25 : 23,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.history_rounded),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'Riwayat',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationBadgeCount extends StatelessWidget {
  final AppSession session;
  final Widget Function(BuildContext context, int unread) builder;

  const NotificationBadgeCount({
    super.key,
    required this.session,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final service = AppNotificationService();
    return StreamBuilder<List<AppNotification>>(
      stream: service.watchFirestoreInbox(session),
      builder: (context, firestoreSnapshot) {
        final firestoreItems = firestoreSnapshot.data ?? const <AppNotification>[];
        return StreamBuilder<List<AppNotification>>(
          stream: service.watchRtdbFallback(session),
          builder: (context, rtdbSnapshot) {
            final rtdbItems = rtdbSnapshot.data ?? const <AppNotification>[];
            final merged = service.mergeInbox(firestoreItems, rtdbItems);
            final unread = merged.where((item) => !item.read).length;
            return builder(context, unread);
          },
        );
      },
    );
  }
}
