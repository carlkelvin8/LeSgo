import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lezgo_rider/presentation/provider/theme_provider.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_more_view.dart';
import 'package:lezgo_rider/presentation/widgets/main/riderside/more/rider_more_components.dart';

Future<void> mountMore(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  bool dark = false,
  bool filipino = false,
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({
    'dark_mode': dark,
    'app_language': filipino ? 'tl' : 'en',
  });
  await tester.pumpWidget(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ref.watch(themeModeProvider),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: reducedMotion,
            ),
            child: child!,
          ),
          home: const Scaffold(body: SafeArea(child: RiderMoreView())),
        ),
      ),
    ),
  );
}

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('More fits $width px in Filipino, dark mode and large text', (
      tester,
    ) async {
      await mountMore(
        tester,
        width: width,
        textScale: 2,
        dark: true,
        filipino: true,
      );
      await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat indefinitely.
      expect(tester.takeException(), isNull);
      expect(find.text('Buksan ang wallet'), findsOneWidget);
      final cards = find.byType(MoreShortcutCard);
      expect(
        tester.getTopLeft(cards.at(1)).dy,
        greaterThan(tester.getBottomLeft(cards.at(0)).dy),
      );
      await tester.scrollUntilVisible(find.byType(Switch), 300);
      await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat indefinitely.
      expect(tester.takeException(), isNull);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });
  }

  testWidgets('Settings persist and language navigation returns to More', (
    tester,
  ) async {
    await mountMore(tester);
    await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat indefinitely.
    await tester.scrollUntilVisible(find.byType(Switch), 250);
    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat indefinitely.
    expect(
      (await SharedPreferences.getInstance()).getBool('dark_mode'),
      isTrue,
    );
    await tester.ensureVisible(find.text('Language'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Language'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat indefinitely.
    expect(find.byType(AppBar), findsOneWidget);
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat indefinitely.
    expect(find.byType(RiderMoreView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced motion displays all sections immediately', (
    tester,
  ) async {
    await mountMore(tester, reducedMotion: true);
    final fades = tester.widgetList<FadeTransition>(
      find.descendant(
        of: find.byType(RiderMoreView),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fades, isNotEmpty);
    expect(fades.every((fade) => fade.opacity.value == 1), isTrue);
    await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat indefinitely.
    expect(tester.takeException(), isNull);
  });
}
