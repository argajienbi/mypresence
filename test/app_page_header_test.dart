import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mypresensi_flutter_stage3/widgets/app_page_header.dart';

const double _topPadding = 24;

Widget _wrap(Widget child) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(
        padding: EdgeInsets.only(top: _topPadding),
      ),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('AppPageHeader tingginya topPadding + 108, judul+subtitle tampil',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const AppPageHeader(
      title: 'Riwayat Presensi',
      subtitle: 'Rekam jejak kehadiran dan pengajuan',
      icon: Icons.history_rounded,
    )));

    expect(find.text('Riwayat Presensi'), findsOneWidget);
    expect(find.text('Rekam jejak kehadiran dan pengajuan'), findsOneWidget);
    // Tombol kembali hanya untuk halaman dalam.
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);

    final size = tester.getSize(find.byType(AppPageHeader));
    expect(size.height, _topPadding + 108);
    expect(size.width, 390);
  });

  testWidgets('AppPageHeader showBack: tombol kembali menutup halaman',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const Scaffold(
                    body: AppPageHeader(
                      title: 'Detail Jadwal',
                      icon: Icons.event_available_rounded,
                      showBack: true,
                    ),
                  ),
                ),
              ),
              child: const Text('Buka'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
    expect(find.text('Detail Jadwal'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Detail Jadwal'), findsNothing);
    expect(find.text('Buka'), findsOneWidget);
  });

  testWidgets('AppPageHeader leading avatar 56 + trailing tampil',
      (tester) async {
    await tester.pumpWidget(_wrap(AppPageHeader(
      eyebrow: 'Selamat malam,',
      title: 'Armin Gandi',
      subtitle: 'Rabu, 28 Okt 2026',
      leading: Container(
        key: const Key('avatar'),
        width: 56,
        height: 56,
        decoration: const BoxDecoration(shape: BoxShape.circle),
      ),
      trailing: const Icon(Icons.notifications_rounded, key: Key('bell')),
    )));

    expect(find.text('Selamat malam,'), findsOneWidget);
    expect(find.text('Armin Gandi'), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('avatar'))),
        const Size(56, 56));
    expect(find.byKey(const Key('bell')), findsOneWidget);
  });

  testWidgets(
      'Geometri Home (pola Run #53): jarak diam kartu 25px, dock kartu = topPadding + 25',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const cardKey = Key('location-card');
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(top: _topPadding),
        ),
        child: Scaffold(
          body: CustomScrollView(
            controller: controller,
            physics: const ClampingScrollPhysics(),
            slivers: [
              const SliverAppBar(
                expandedHeight: 108,
                collapsedHeight: 0,
                toolbarHeight: 0,
                pinned: true,
                floating: false,
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: AppPageHeader(
                    title: 'Home',
                    icon: Icons.home_rounded,
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                // Cerminan _StickyCardDelegate di home_page.dart (tidak
                // diubah ronde ini): tinggi tetap 110, padding atas 25.
                delegate: _TestStickyCardDelegate(
                  height: 110,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 25, 18, 8),
                    child: Container(
                      key: cardKey,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 600)),
              const SliverToBoxAdapter(child: SizedBox(height: 220)),
            ],
          ),
        ),
      ),
    ));
    await tester.pump();

    // Diam: header bawah = topPadding + 108, kartu mulai 25px di bawahnya.
    final headerBottom =
        tester.getBottomLeft(find.byType(AppPageHeader)).dy;
    final cardTopRest = tester.getTopLeft(find.byKey(cardKey)).dy;
    expect(headerBottom, _topPadding + 108);
    expect(cardTopRest - headerBottom, 25);

    // Scroll sampai mentok: kartu dock tepat 25px di bawah status bar.
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    final cardTopDocked = tester.getTopLeft(find.byKey(cardKey)).dy;
    expect(cardTopDocked, _topPadding + 25);
  });
}

/// Cerminan persis _StickyCardDelegate (home_page.dart): tinggi tetap,
/// tanpa strip status bar, anak apa adanya. Dipakai hanya untuk menguji
/// geometri sliver (delegate produksi bersifat privat & tidak diubah).
class _TestStickyCardDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const _TestStickyCardDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: SizedBox(height: height, child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _TestStickyCardDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
