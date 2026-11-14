import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/presentation/provider/main/lespay/lespay_provider.dart';
import 'package:lesgo/presentation/widgets/lespay/top_up_dialog.dart';

class FakeLespay extends LespayNotifier {
  FakeLespay({this.failWith});

  /// Error message the fake publishes in state when the top-up fails.
  final String? failWith;
  final requested = <double>[];

  @override
  Future<TopUpCheckout?> startTopUp(double amount) async {
    requested.add(amount);
    if (failWith != null) {
      state = state.copyWith(error: failWith);
    }
    return null;
  }
}

void main() {
  Future<void> pumpDialog(WidgetTester tester, FakeLespay fake) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [lespayProvider.overrideWith((ref) => fake)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TopUpDialog(parentContext: context),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> submit(WidgetTester tester, String amount) async {
    await tester.enterText(find.byType(TextFormField), amount);
    await tester.pump();
    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows provider error inline when startTopUp returns null', (
    tester,
  ) async {
    final fake = FakeLespay(failWith: 'Gateway is down');
    await pumpDialog(tester, fake);
    expect(find.byKey(const Key('top_up_error')), findsNothing);

    await submit(tester, '500');

    expect(fake.requested, [500.0]);
    final text = tester.widget<Text>(find.byKey(const Key('top_up_error')));
    expect(text.data, 'Gateway is down');
    // Dialog stays open so the user can retry.
    expect(find.byType(TopUpDialog), findsOneWidget);
  });

  testWidgets('falls back to a generic inline error when state has none', (
    tester,
  ) async {
    final fake = FakeLespay();
    await pumpDialog(tester, fake);

    await submit(tester, '500');

    final text = tester.widget<Text>(find.byKey(const Key('top_up_error')));
    expect(text.data, 'Could not start top-up. Please try again.');
  });

  testWidgets('invalid amount is rejected before reaching the provider', (
    tester,
  ) async {
    final fake = FakeLespay();
    await pumpDialog(tester, fake);

    await submit(tester, '');

    expect(fake.requested, isEmpty);
    expect(find.byKey(const Key('top_up_error')), findsNothing);
  });

  testWidgets('retrying calls the provider again and keeps the error visible', (tester) async {
    final fake = FakeLespay(failWith: 'Gateway is down');
    await pumpDialog(tester, fake);
    await submit(tester, '500');
    expect(find.byKey(const Key('top_up_error')), findsOneWidget);

    // Second attempt fails too; requested twice proves the retry went through.
    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();
    expect(fake.requested, [500.0, 500.0]);
    expect(find.byKey(const Key('top_up_error')), findsOneWidget);
  });
}
