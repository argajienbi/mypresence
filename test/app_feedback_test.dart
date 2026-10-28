import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mypresensi_flutter_stage3/widgets/app_feedback.dart';

void main() {
  // Sheet kalender riwayat memakai DraggableScrollableSheet di dalam
  // showAppBottomSheet — komposisi ini harus dibuka tanpa error layout
  // (DraggableScrollableSheet butuh tinggi yang dibatasi rute modal).
  testWidgets('showAppBottomSheet menerima DraggableScrollableSheet',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAppBottomSheet<void>(
                context: context,
                backgroundColor: const Color(0xFFF1F5F9),
                child: DraggableScrollableSheet(
                  initialChildSize: .78,
                  minChildSize: .48,
                  maxChildSize: .94,
                  builder: (context, controller) => ListView(
                    controller: controller,
                    children: const [Text('Kalender')],
                  ),
                ),
              ),
              child: const Text('Buka'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
    expect(find.text('Kalender'), findsOneWidget);
  });

  testWidgets('showAppBottomSheet membuka konten biasa', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAppBottomSheet<void>(
                context: context,
                child: const Text('Isi sheet'),
              ),
              child: const Text('Buka'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
    expect(find.text('Isi sheet'), findsOneWidget);
  });
}
