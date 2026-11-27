import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/data/data_source/referral_remote_datasource.dart';
import 'package:lesgo/presentation/provider/main/profile/profile_provider.dart';
import 'package:lesgo/presentation/screens/main/referral/referral_dashboard_screen.dart';
import 'package:lesgo/presentation/widgets/profile/invite_friends_sheet.dart';

class _Referral implements ReferralRemoteDataSource {
  @override
  Future<ReferralDashboardDto> getDashboard() async =>
      ReferralDashboardDto.fromJson({
        'referral_code': 'ABC12345',
        'invites_sent': 7,
        'friends_joined': 3,
        'pending_rewards': 1,
        'points_earned': 150,
        'recent_rewards': [
          {'title': 'Maria joined', 'status': 'paid', 'points': 50, 'date': '2026-11-20T10:00:00Z'},
          {'title': 'Juan joined', 'status': 'pending', 'points': 50},
        ],
      });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profile extends ProfileNotifier {
  @override
  Future<void> loadProfile() async {}
}

Future<void> _size(WidgetTester tester, double w, double scale) async {
  tester.view.physicalSize = Size(w, 1400);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

void main() {
  setUp(() => getIt.registerSingleton<ReferralRemoteDataSource>(_Referral()));
  tearDown(getIt.reset);

  Future<void> openSheet(WidgetTester tester, {String code = 'ABC12345'}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileProvider.overrideWith((_) => _Profile())],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => InviteFriendsSheet.show(
                  context,
                  referralCode: code,
                  userName: 'Test',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('InviteFriendsSheet', () {
    testWidgets('shows the pitch, steps, code and share actions', (tester) async {
      await _size(tester, 700, 1.0);
      await openSheet(tester);

      expect(find.textContaining('earn together'), findsOneWidget);
      expect(find.text('Share your code'), findsOneWidget);
      expect(find.text('ABC12345'), findsOneWidget);
      expect(find.text('Share invite link'), findsOneWidget);
      expect(find.text('Copy invite message'), findsOneWidget);
      // Real stats show up once loaded.
      expect(find.text('Friends joined'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('copying the code gives clear feedback', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _size(tester, 700, 1.0);
      await openSheet(tester);

      await tester.tap(find.text('Copy'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(copied, 'ABC12345');
      expect(find.text('Copied'), findsOneWidget);
      // ...and goes back after a moment.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('without a code the actions are disabled', (tester) async {
      await _size(tester, 700, 1.0);
      await openSheet(tester, code: '');
      expect(find.text('Getting your code…'), findsOneWidget);
      final share = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(share.onPressed, isNull);
    });

    for (final c in [(320.0, 1.0), (320.0, 2.0)]) {
      testWidgets('no overflow at ${c.$1}px / ${c.$2}x text', (tester) async {
        await _size(tester, c.$1, c.$2);
        await openSheet(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('ReferralDashboardScreen', () {
    testWidgets('stats, code and recent rewards', (tester) async {
      await _size(tester, 700, 1.0);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [profileProvider.overrideWith((_) => _Profile())],
          child: const MaterialApp(home: ReferralDashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Points earned'), findsOneWidget);
      expect(find.text('ABC12345'), findsOneWidget);
      expect(find.text('Maria joined'), findsOneWidget);
      expect(find.text('+50 pts'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });
}
