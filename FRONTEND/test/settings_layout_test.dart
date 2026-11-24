import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/services/app_preferences_service.dart';
import 'package:lesgo/core/utils/app_localization.dart';
import 'package:lesgo/presentation/screens/main/settings_screen.dart';

void main() {
  testWidgets(
    'settings reflects the current language and gives profile editing a label',
    (t) async {
      SharedPreferences.setMockInitialValues({});
      getIt.registerSingleton<AppPreferencesService>(
        AppPreferencesService(await SharedPreferences.getInstance()),
      );
      addTearDown(getIt.reset);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Edit profile'), findsOneWidget);
      await container
          .read(appLanguageProvider.notifier)
          .setLanguage(AppLanguage.filipino);
      await t.pumpAndSettle();
      expect(find.text('I-edit ang profile'), findsOneWidget);
      await t.scrollUntilVisible(find.text('Filipino'), 240);
      expect(find.text('Filipino'), findsOneWidget);
    },
  );

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('settings fits at ${width}px / ${scale}x text', (t) async {
        SharedPreferences.setMockInitialValues({});
        getIt.registerSingleton<AppPreferencesService>(
          AppPreferencesService(await SharedPreferences.getInstance()),
        );
        addTearDown(getIt.reset);
        t.view.physicalSize = Size(width, 2600);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: const SettingsScreen(),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(t.widget<Text>(find.text('Settings')).style?.fontFamily, 'Sora');
        expect(t.takeException(), isNull);
      });
    }
  }
}
