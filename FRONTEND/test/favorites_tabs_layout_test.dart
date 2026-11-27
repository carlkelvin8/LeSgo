import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/services/favorites_service.dart';
import 'package:lesgo/presentation/screens/main/favorites_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<TabBar> _pump(WidgetTester tester, double width) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  if (getIt.isRegistered<FavoritesService>()) {
    getIt.unregister<FavoritesService>();
  }
  getIt.registerSingleton<FavoritesService>(FavoritesService(prefs));
  addTearDown(() => getIt.unregister<FavoritesService>());
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: FavoritesScreen())),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return tester.widget<TabBar>(find.byType(TabBar));
}

void main() {
  testWidgets('tabs share the full width when they fit (wide phone)', (
    tester,
  ) async {
    final bar = await _pump(tester, 800);
    expect(bar.isScrollable, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tabs scroll instead of truncating on a narrow phone', (
    tester,
  ) async {
    final bar = await _pump(tester, 320);
    expect(bar.isScrollable, isTrue);
    expect(tester.takeException(), isNull);
  });
}
