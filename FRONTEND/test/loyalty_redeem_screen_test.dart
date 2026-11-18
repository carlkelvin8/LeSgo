import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/data/data_source/loyalty_remote_datasource.dart';
import 'package:lesgo/presentation/provider/main/loyalty/loyalty_provider.dart';
import 'package:lesgo/presentation/provider/main/profile/profile_provider.dart';
import 'package:lesgo/presentation/screens/main/loyalty_redeem_screen.dart';
import 'package:lesgo/presentation/widgets/loyalty/loyalty_progress.dart';

// The four rewards from the backend's config/loyalty.php.
const _catalog = [
  LoyaltyRewardDto(id: 1, title: '₱50 LesGo Voucher', description: 'Redeem for ₱50 off your next LesGo delivery booking.', pointsCost: 500, rewardType: 'voucher'),
  LoyaltyRewardDto(id: 2, title: '₱100 LesEat Voucher', description: 'Redeem for ₱100 off your next LesEat food order.', pointsCost: 900, rewardType: 'voucher'),
  LoyaltyRewardDto(id: 3, title: 'Free Delivery Pass', description: 'One free delivery fee waiver on any LesGo or LesEat order.', pointsCost: 750, rewardType: 'voucher'),
  LoyaltyRewardDto(id: 4, title: '₱25 LesRide Credit', description: 'Redeem for ₱25 off your next LesRide booking.', pointsCost: 300, rewardType: 'voucher'),
];

LoyaltyReward _r(int id, int cost, {bool available = true}) => LoyaltyReward(
  id: id, title: 'R$id', description: '', pointsCost: cost, rewardType: 'voucher', available: available,
);

class _Loyalty implements LoyaltyRemoteDataSource {
  int? redeemedId;

  @override
  Future<List<LoyaltyRewardDto>> getRewards() async => _catalog;

  @override
  Future<LoyaltyRedeemResultDto> redeemReward(int rewardId) async {
    redeemedId = rewardId;
    return const LoyaltyRedeemResultDto(success: true, message: 'ok');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profile extends ProfileNotifier {
  _Profile(int points) {
    state = ProfileState(points: points, name: 'Test Customer', referralCode: 'ABC123');
  }

  @override
  Future<void> loadProfile() async {}

  @override
  Future<void> refreshProfile() async {}
}

void main() {
  group('LoyaltyProgress', () {
    final rewards = [_r(1, 500), _r(2, 900), _r(3, 750), _r(4, 300)];

    test('next goal is the cheapest reward the customer cannot afford yet', () {
      expect(LoyaltyProgress.nextGoal(0, rewards)!.id, 4);
      expect(LoyaltyProgress.nextGoal(300, rewards)!.id, 1);
      expect(LoyaltyProgress.nextGoal(600, rewards)!.id, 3);
      expect(LoyaltyProgress.nextGoal(900, rewards), isNull);
    });

    test('unavailable rewards are never a goal or redeemable', () {
      final list = [_r(1, 100, available: false), _r(2, 400)];
      expect(LoyaltyProgress.nextGoal(0, list)!.id, 2);
      expect(LoyaltyProgress.redeemableCount(1000, list), 1);
      expect(LoyaltyProgress.canRedeem(list.first, 1000), isFalse);
    });

    test('redeemable rewards come first, then cheapest to dearest, unavailable last', () {
      final list = [_r(1, 500), _r(2, 900), _r(3, 750, available: false), _r(4, 300)];
      expect(LoyaltyProgress.sorted(520, list).map((r) => r.id), [4, 1, 2, 3]);
      expect(LoyaltyProgress.sorted(0, list).map((r) => r.id), [4, 1, 2, 3]);
    });

    test('progress is clamped and counts what is left', () {
      expect(LoyaltyProgress.fraction(150, 300), 0.5);
      expect(LoyaltyProgress.fraction(900, 300), 1.0);
      expect(LoyaltyProgress.fraction(0, 0), 1.0);
      expect(LoyaltyProgress.pointsToGo(120, 500), 380);
      expect(LoyaltyProgress.pointsToGo(900, 500), 0);
    });

    test('numbers get thousands separators', () {
      expect(LoyaltyProgress.format(0), '0');
      expect(LoyaltyProgress.format(950), '950');
      expect(LoyaltyProgress.format(1250), '1,250');
      expect(LoyaltyProgress.format(1000000), '1,000,000');
    });
  });

  group('Redeem Points screen', () {
    late _Loyalty source;

    setUp(() {
      source = _Loyalty();
      getIt.registerSingleton<LoyaltyRemoteDataSource>(source);
    });

    tearDown(getIt.reset);

    Future<void> pump(WidgetTester tester, int points) async {
      tester.view.physicalSize = const Size(402, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [profileProvider.overrideWith((_) => _Profile(points))],
          child: const MaterialApp(home: LoyaltyRedeemScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('with 0 points every reward is locked, with progress and what is missing',
        (tester) async {
      await pump(tester, 0);

      for (final id in [1, 2, 3, 4]) {
        expect(find.byKey(ValueKey('reward-progress-$id')), findsOneWidget);
        expect(find.byKey(ValueKey('redeem-button-$id')), findsNothing);
      }
      expect(find.text('500 more to unlock'), findsOneWidget);
      expect(find.text('300 more to unlock'), findsOneWidget);
      expect(find.byKey(const ValueKey('ready-banner')), findsNothing);
      // The nearest goal is highlighted at the top.
      expect(find.text('Next reward: ₱25 LesRide Credit'), findsOneWidget);
      expect(find.text('300 pts to go'), findsOneWidget);
    });

    testWidgets('offers shortcuts to earn more points', (tester) async {
      await pump(tester, 0);

      expect(find.text('Earn more points'), findsOneWidget);
      expect(find.byKey(const ValueKey('earn-invite')), findsOneWidget);
      expect(find.byKey(const ValueKey('earn-missions')), findsOneWidget);
    });

    testWidgets('an affordable reward shows a clear Redeem now action and a ready banner',
        (tester) async {
      await pump(tester, 520);

      expect(find.byKey(const ValueKey('redeem-button-4')), findsOneWidget, reason: '300 pts');
      expect(find.byKey(const ValueKey('redeem-button-1')), findsOneWidget, reason: '500 pts');
      expect(find.byKey(const ValueKey('redeem-button-2')), findsNothing, reason: '900 pts');
      expect(find.text('2 rewards are ready to redeem!'), findsOneWidget);
      expect(find.text('Redeem now'), findsNWidgets(2));
      expect(find.text('230 more to unlock'), findsOneWidget, reason: 'Free Delivery Pass 750');
    });

    testWidgets('redeeming asks for confirmation, shows what is left, then redeems',
        (tester) async {
      await pump(tester, 520);

      await tester.tap(find.byKey(const ValueKey('redeem-button-4')));
      await tester.pumpAndSettle();

      expect(find.text('Redeem reward?'), findsOneWidget);
      expect(find.textContaining('You will have 220 points left.'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(source.redeemedId, isNull, reason: 'cancelling must not spend points');

      await tester.tap(find.byKey(const ValueKey('redeem-button-4')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Redeem'));
      await tester.pumpAndSettle();
      expect(source.redeemedId, 4);
    });

    testWidgets('large balances are formatted with separators', (tester) async {
      await pump(tester, 1250);

      expect(find.text('1,250'), findsOneWidget);
      expect(find.text('4 rewards are ready to redeem!'), findsOneWidget);
      // Nothing left to aim for, so no next-goal bar.
      expect(find.byKey(const ValueKey('next-goal-progress')), findsNothing);
    });
  });
}
