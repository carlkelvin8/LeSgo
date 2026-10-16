import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection.dart';
import '../../core/services/app_preferences_service.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier({AppPreferencesService? preferences})
      : _preferences = preferences ?? getIt<AppPreferencesService>(),
        super((preferences ?? getIt<AppPreferencesService>()).darkModeEnabled
            ? ThemeMode.dark : ThemeMode.light);

  final AppPreferencesService _preferences;

  Future<void> setDarkMode(bool enabled) async {
    await _preferences.setDarkModeEnabled(enabled);
    if (mounted) state = enabled ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() => setDarkMode(state != ThemeMode.dark);
}
