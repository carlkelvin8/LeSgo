import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lesgo/core/constants/routers/app_router.dart';
import 'package:lesgo/core/constants/routers/main/main_routes.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/data/data_source/missions_remote_datasource.dart';
import 'package:lesgo/data/data_source/dto/missions/mission_dto.dart';
import 'package:lesgo/presentation/screens/main/missions_screen.dart';
import 'package:lesgo/presentation/widgets/home/app_drawer.dart';
import 'package:lesgo/presentation/provider/main/profile/profile_provider.dart';

class _MissionsSource implements MissionsRemoteDataSource {
  @override
  Future<MissionsResponseDto> getMissions() async =>
      MissionsResponseDto(success: true, message: 'OK', data: []);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profile extends ProfileNotifier {
  @override
  Future<void> loadProfile() async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('drawer entry returns home repeatedly with UI and system Back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    getIt.registerSingleton<MissionsRemoteDataSource>(_MissionsSource());
    addTearDown(getIt.reset);
    final navigator = GlobalKey<NavigatorState>();
    final scaffold = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileProvider.overrideWith((_) => _Profile())],
        child: MaterialApp(
          navigatorKey: navigator,
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: Scaffold(
            key: scaffold,
            drawer: const AppDrawer(),
            body: const Text('Home caller'),
          ),
        ),
      ),
    );
    for (final systemBack in [false, true, false]) {
      scaffold.currentState!.openDrawer();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Missions'));
      await tester.pumpAndSettle();
      // SVG decoding completes outside the fake animation clock. Exercise the
      // loaded picture; otherwise the old overlapping-banner bug passes.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MissionsScreen), findsOneWidget);
      if (systemBack) {
        await tester.binding.handlePopRoute();
      } else {
        final button = find.ancestor(
          of: find.byIcon(Icons.arrow_back_ios),
          matching: find.byType(IconButton),
        );
        final rect = tester.getRect(button);
        await tester.tapAt(Offset(rect.center.dx, rect.bottom - 4));
      }
      await tester.pumpAndSettle();
      expect(find.text('Home caller'), findsOneWidget);
      expect(find.byType(MissionsScreen), findsNothing);
      expect(scaffold.currentState!.isDrawerOpen, isFalse);
      expect(navigator.currentState!.canPop(), isFalse);
    }
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 600.0]) {
    for (final systemBack in [false, true]) {
      testWidgets(
        'Missions back restores caller repeatedly at $width (system=$systemBack)',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          getIt.registerSingleton<MissionsRemoteDataSource>(_MissionsSource());
          addTearDown(getIt.reset);
          final navigator = GlobalKey<NavigatorState>();
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                navigatorKey: navigator,
                onGenerateRoute: AppRouter.onGenerateRoute,
                home: const Scaffold(body: Text('Home caller')),
              ),
            ),
          );
          // Preserve an arbitrary caller rather than redirecting to a fixed home.
          navigator.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Previous page')),
            ),
          );
          await tester.pumpAndSettle();
          for (var visit = 0; visit < 3; visit++) {
            navigator.currentState!.pushNamed(MainRoutes.missions);
            await tester.pumpAndSettle();
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 300)),
            );
            await tester.pumpAndSettle();
            expect(find.byType(MissionsScreen), findsOneWidget);
            if (systemBack) {
              await tester.binding.handlePopRoute();
            } else {
              final button = find.ancestor(
                of: find.byIcon(Icons.arrow_back_ios),
                matching: find.byType(IconButton),
              );
              final rect = tester.getRect(button);
              // The lower part of the button overlaps the decorative banner.
              await tester.tapAt(Offset(rect.center.dx, rect.bottom - 4));
            }
            await tester.pumpAndSettle();
            expect(find.text('Previous page'), findsOneWidget);
            expect(find.byType(MissionsScreen), findsNothing);
            expect(navigator.currentState!.canPop(), isTrue);
          }
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.text('Home caller'), findsOneWidget);
          expect(navigator.currentState!.canPop(), isFalse);
        },
      );
    }
  }
}
