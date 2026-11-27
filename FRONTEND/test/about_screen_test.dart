import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/constants/app_info.dart';
import 'package:lesgo/presentation/screens/main/about_screen.dart';

Future<void> _pump(WidgetTester tester, double width, double scale) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: AboutScreen())),
  );
  await tester.pump(const Duration(milliseconds: 1600));
}

void main() {
  for (final c in [(320.0, 1.0), (390.0, 1.0), (320.0, 2.0)]) {
    testWidgets('About lays out without overflow at ${c.$1}px, ${c.$2}x text', (tester) async {
      await _pump(tester, c.$1, c.$2);
      expect(tester.takeException(), isNull);
      // Scroll the whole page.
      final scroll = find.byType(SingleChildScrollView);
      for (var i = 0; i < 8; i++) {
        await tester.drag(scroll, const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
      expect(find.textContaining('${AppInfo.version}'), findsWidgets);
    });
  }

  testWidgets('keeps to a few plain sections', (tester) async {
    await _pump(tester, 390, 1.0);
    expect(find.text('Everyday life.\nA little easier.'), findsOneWidget);
    expect(find.text('Meet IBOW'), findsOneWidget);
    // The old marketing sections are gone.
    expect(find.text('WHAT WE DO'), findsNothing);
    expect(find.text('HOW IT WORKS'), findsNothing);
    expect(find.text('WHY LESGO'), findsNothing);
    await tester.dragUntilVisible(
      find.text('Open-source licenses'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    expect(find.text('Earn with LeSgo'), findsOneWidget);
  });
}
