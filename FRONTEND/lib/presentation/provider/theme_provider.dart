import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection.dart';
import '../../core/services/app_preferences_service.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(_loadInitial());

  static ThemeMode _loadInitial() {
    final prefs = getIt<AppPreferencesService>();
    if (prefs.darkModeEnabled) return ThemeMode.dark;
    return ThemeMode.light;
  }

  Future<void> setDarkMode(bool enabled) async {
    await getIt<AppPreferencesService>().setDarkModeEnabled(enabled);
    state = enabled ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() => setDarkMode(state != ThemeMode.dark);
}
