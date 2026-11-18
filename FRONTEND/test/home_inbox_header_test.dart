import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/constants/routers/main/main_routes.dart';
import 'package:lesgo/core/di/local_storage_service.dart';
import 'package:lesgo/domain/use_cases/login_usecase.dart';
import 'package:lesgo/domain/use_cases/logout_usecase.dart';
import 'package:lesgo/presentation/provider/auth/auth_provider.dart';
import 'package:lesgo/presentation/widgets/home/home_header_section.dart';
import 'package:lesgo/presentation/widgets/home/home_quick_access_section.dart';
import 'package:lesgo/presentation/widgets/home/location_header.dart';
import 'package:lesgo/presentation/widgets/home/quick_access_card.dart';

class _Login implements LoginUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Logout implements LogoutUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Storage implements LocalStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _setWidth(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('LocationHeader', () {
    testWidgets('shows an Inbox button at the top-right and reports taps', (tester) async {
      await _setWidth(tester, 402);
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: LocationHeader(location: 'Centro I, Claveria', onInboxTap: () => taps++))),
      );

      final button = find.byKey(const ValueKey('home-inbox-button'));
      expect(button, findsOneWidget);
      expect(find.bySemanticsLabel('Inbox'), findsOneWidget);

      // Right edge of the screen, same band as the location text.
      final box = tester.getRect(button);
      expect(box.right, greaterThan(402 - 40), reason: 'top-right corner');
      expect(box.top, lessThan(120));
      expect(find.text('Centro I, Claveria'), findsOneWidget);

      await tester.tap(button);
      expect(taps, 1);
    });

    testWidgets('has no Inbox button when no handler is given', (tester) async {
      await _setWidth(tester, 402);
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LocationHeader(location: 'Somewhere'))));

      expect(find.byKey(const ValueKey('home-inbox-button')), findsNothing);
    });

    testWidgets('a long address on a narrow phone shrinks instead of overflowing', (tester) async {
      await _setWidth(tester, 320);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationHeader(
              location: 'Unit 12, Building 4, Some Very Long Subdivision Name, Claveria, Cagayan Valley',
              onInboxTap: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('home-inbox-button')), findsOneWidget);
    });
  });

  group('Home header wiring', () {
    testWidgets('tapping the Inbox button opens the inbox', (tester) async {
      await _setWidth(tester, 402);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith((_) => AuthNotifier(_Login(), _Logout(), _Storage()))],
          child: MaterialApp(
            routes: {MainRoutes.inbox: (_) => const Scaffold(body: Text('INBOX SCREEN'))},
            home: const Scaffold(body: HomeHeaderSection()),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('home-inbox-button')));
      await tester.pumpAndSettle();

      expect(find.text('INBOX SCREEN'), findsOneWidget);
    });
  });

  group('HomeQuickAccessSection', () {
    testWidgets('only the wallet card is left, full width, and no Inbox card', (tester) async {
      await _setWidth(tester, 402);
      await tester.pumpWidget(
        MaterialApp(
          routes: {MainRoutes.lespay: (_) => const Scaffold(body: Text('WALLET SCREEN'))},
          home: const Scaffold(body: HomeQuickAccessSection()),
        ),
      );

      final cards = find.byType(QuickAccessCard);
      expect(cards, findsOneWidget);
      expect(tester.widget<QuickAccessCard>(cards).wide, isTrue);
      expect(tester.widget<QuickAccessCard>(cards).iconPath, contains('Wallet'));
      expect(find.textContaining('Inbox'), findsNothing);
      // Spans the row (screen width minus the 16px side padding).
      expect(tester.getSize(cards).width, closeTo(402 - 32, 1));

      await tester.tap(cards);
      await tester.pumpAndSettle();
      expect(find.text('WALLET SCREEN'), findsOneWidget);
    });

    testWidgets('the wide card does not overflow at large text on a narrow phone', (tester) async {
      await _setWidth(tester, 320);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: HomeQuickAccessSection()))));

      expect(tester.takeException(), isNull);
    });
  });
}
