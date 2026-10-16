import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lezgo_rider/core/utils/rider_earnings_utils.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_earnings_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_earnings_insights_provider.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_earnings_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_earnings_insights_screen.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/rider_earnings_hub_screen.dart';

void main() {
  testWidgets(
    'Unified earnings switches tabs with one header and report action',
    (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            riderEarningsProvider.overrideWith(
              (ref) async => const RiderEarningsState(
                period: RiderEarningsPeriod.today,
                entries: [],
                summary: RiderEarningsSummary(
                  totalEarnings: 0,
                  completedTrips: 0,
                  averagePerTrip: 0,
                ),
              ),
            ),
            riderEarningsInsightsProvider.overrideWith(
              (ref) async => const RiderEarningsInsightsState(),
            ),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: const RiderEarningsHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Completed Trips'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.ios_share_rounded),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('Earnings · Last 30 days'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      await tester.tap(find.text('Trips'));
      await tester.pumpAndSettle();
      expect(find.text('Completed Trips'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final insights in [false, true]) {
    testWidgets(
      'Earnings page fits narrow screen and large text: insights=$insights',
      (tester) async {
        tester.view.physicalSize = const Size(320, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({'app_language': 'en'});
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              riderEarningsProvider.overrideWith(
                (ref) async => RiderEarningsState(
                  period: ref.watch(riderEarningsPeriodProvider),
                  entries: const [],
                  summary: const RiderEarningsSummary(
                    totalEarnings: 0,
                    completedTrips: 0,
                    averagePerTrip: 0,
                  ),
                ),
              ),
              riderEarningsInsightsProvider.overrideWith(
                (ref) async => const RiderEarningsInsightsState(),
              ),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: insights
                  ? const RiderEarningsInsightsScreen()
                  : const RiderEarningsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('PHP 0.00'), findsWidgets);
        expect(tester.takeException(), isNull);
        if (!insights) {
          await tester.tap(find.text('This Month'));
          await tester.pumpAndSettle();
          expect(find.text('Net earnings · This Month'), findsOneWidget);
        }
        await tester.drag(find.byType(ListView).first, const Offset(0, -650));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
