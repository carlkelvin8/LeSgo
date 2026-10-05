import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lezgo_rider/presentation/provider/main/riderside/rider_history_provider.dart';
import 'package:lezgo_rider/presentation/screens/main/riderside/views/rider_history_view.dart';
import 'package:lezgo_rider/presentation/widgets/main/riderside/history/rider_history_filter_tabs.dart';

class _History extends RiderHistoryNotifier {
  _History(super.ref);
  int refreshes = 0;
  @override
  Future<void> loadHistory({bool silent = false}) async {
    refreshes++;
  }
}

void main() {
  for (final large in [false, true]) {
    testWidgets(
      'History filters and empty refresh work with large text: $large',
      (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({
          'app_language': large ? 'tl' : 'en',
        });
        late _History history;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              riderHistoryProvider.overrideWith(
                (ref) => history = _History(ref),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(
                brightness: large ? Brightness.dark : Brightness.light,
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(large ? 2 : 1),
                  disableAnimations: large,
                ),
                child: child!,
              ),
              home: const Scaffold(body: RiderHistoryView()),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat.
        expect(tester.takeException(), isNull);
        final filter = find.descendant(
          of: find.byType(RiderHistoryFilterTabs),
          matching: find.text(large ? 'Natapos' : 'Completed'),
        );
        if (large) {
          await tester.drag(find.byType(CustomScrollView), const Offset(0, -950));
          await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat.
        }
        await tester.ensureVisible(filter);
        await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat.
        await tester.tap(filter);
        await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat.
        expect(history.state.selectedFilter, 'Completed');
        expect(tester.takeException(), isNull);
        final clear = find.text(
          large ? 'Lahat ng booking' : 'View all bookings',
        );
        await tester.scrollUntilVisible(clear, 200, scrollable: find.byType(Scrollable).last);
        await tester.tap(clear);
        await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat.
        expect(history.state.selectedFilter, 'All');
        final refresh = find.text(large ? 'I-refresh' : 'Refresh history');
        await tester.scrollUntilVisible(refresh, 200, scrollable: find.byType(Scrollable).last);
        await tester.tap(refresh);
        await tester.pump(const Duration(seconds: 1)); // Decorative animations repeat.
        expect(history.refreshes, greaterThan(1));
        expect(tester.takeException(), isNull);
      },
    );
  }
}


