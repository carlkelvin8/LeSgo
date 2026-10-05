import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/services/app_preferences_service.dart';
import 'package:lesgo/core/theme/app_theme.dart';
import 'package:lesgo/presentation/provider/theme_provider.dart';
import 'package:lesgo/presentation/screens/main/settings_screen.dart';

void main() {
  testWidgets('settings cards and labels follow persisted theme with readable contrast', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = AppPreferencesService(await SharedPreferences.getInstance());
    getIt.registerSingleton<AppPreferencesService>(prefs);
    addTearDown(getIt.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container,
      child: Consumer(builder: (context, ref, _) => MaterialApp(
        theme: AppTheme.light, darkTheme: AppTheme.dark,
        themeMode: ref.watch(themeModeProvider), home: const SettingsScreen(),
      ))));
    await tester.pumpAndSettle();
    for (final dark in [false, true, false]) {
      await container.read(themeModeProvider.notifier).setDarkMode(dark);
      await tester.pumpAndSettle();
      expect(prefs.darkModeEnabled, dark);
      final title = tester.widget<Text>(find.text('Settings'));
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      final a = title.style!.color!.computeLuminance();
      final b = appBar.backgroundColor!.computeLuminance();
      final contrast = ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05);
      expect(contrast, greaterThanOrEqualTo(4.5));
      final cards = tester.widgetList<Container>(find.byType(Container))
          .where((c) => c.decoration is BoxDecoration)
          .map((c) => (c.decoration! as BoxDecoration).color)
          .whereType<Color>();
      expect(cards, isNotEmpty);
      if (dark) expect(cards.any((c) => c.computeLuminance() > .9), isFalse);
      expect(tester.takeException(), isNull);
    }
  });
}
