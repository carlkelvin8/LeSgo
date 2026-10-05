import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_profile_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_wallet_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_mission_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_orders_provider.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_profile_view.dart';

class ProfileFixture extends RiderProfileNotifier {
  ProfileFixture(super.ref, RiderProfileState initial) {
    state = initial;
  }
  int refreshCount = 0;
  @override
  Future<void> loadProfile({bool silent = false}) async {
    refreshCount++;
  }
}

class WalletFixture extends StateNotifier<RiderWalletState>
    implements RiderWalletNotifier {
  WalletFixture() : super(const RiderWalletState(balance: 100));
  @override
  Future<void> loadWallet({bool silent = false}) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MissionFixture extends StateNotifier<RiderMissionState>
    implements RiderMissionNotifier {
  MissionFixture() : super(const RiderMissionState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class OrdersFixture extends StateNotifier<RiderOrdersState>
    implements RiderOrdersNotifier {
  OrdersFixture() : super(RiderOrdersState());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> mountProfile(
  WidgetTester tester, {
  double width = 390,
  double scale = 1,
  bool dark = false,
  bool filipino = false,
  RiderProfileState profile = const RiderProfileState(
    name: 'Carl',
    contact: '09123456789',
    referralCode: 'RIDER42',
  ),
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({
    'app_language': filipino ? 'tl' : 'en',
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        riderProfileProvider.overrideWith(
          (ref) => ProfileFixture(ref, profile),
        ),
        riderWalletProvider.overrideWith((ref) => WalletFixture()),
        riderMissionProvider.overrideWith((ref) => MissionFixture()),
        riderOrdersProvider.overrideWith((ref) => OrdersFixture()),
      ],
      child: MaterialApp(
        theme: ThemeData(
          fontFamily: 'TT Fors',
          brightness: dark ? Brightness.dark : Brightness.light,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const Scaffold(body: RiderProfileView()),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat indefinitely.
}

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets(
      'Profile handles long details and large Filipino text at $width',
      (tester) async {
        await mountProfile(
          tester,
          width: width,
          scale: 2,
          dark: true,
          filipino: true,
          profile: const RiderProfileState(
            name: 'Maria Christina Dela Cruz Santos',
            address:
                'Unit 1205, Building 3, Example Village, Quezon City, Metro Manila',
            contact: '+63 912 345 6789',
            vehicle: 'Motorcycle with a long model name',
            plateNumber: 'ABC123456',
            referralCode: 'LONGREFERRAL12345',
          ),
        );
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Suriin ang permanenteng pagtanggal ng account'),
          400,
        );
        await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat indefinitely.
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Referral copy writes the exact code', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
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
    await mountProfile(tester);
    await tester.scrollUntilVisible(find.byTooltip('Copy referral code'), 250);
    await tester.tap(find.byTooltip('Copy referral code'));
    await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat indefinitely.
    expect(copied, 'RIDER42');
    expect(find.text('Copied!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Copy'), findsOneWidget);
  });
  testWidgets('Missing details and refresh failures remain usable', (
    tester,
  ) async {
    await mountProfile(
      tester,
      profile: const RiderProfileState(error: 'offline'),
    );
    expect(find.text('Not added yet'), findsWidgets);
    expect(find.byTooltip('Copy referral code'), findsNothing);
    await tester.ensureVisible(find.text('Try Again'));
    await tester.tap(find.text('Try Again'));
    final context = tester.element(find.byType(RiderProfileView));
    final notifier =
        ProviderScope.containerOf(context).read(riderProfileProvider.notifier)
            as ProfileFixture;
    expect(notifier.refreshCount, 1);
    expect(tester.takeException(), isNull);
  });
}
