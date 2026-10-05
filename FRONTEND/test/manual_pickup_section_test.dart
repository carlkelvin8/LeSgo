import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/presentation/provider/main/booking/lesbuy/manual_order_provider.dart';
import 'package:lesgo/presentation/widgets/booking/lesbuy/manual_order/manual_pickup_section.dart';

void main() {
  testWidgets('buying address is editable inline and requires a pickup pin', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ManualPickupSection()),
          ),
        ),
      ),
    );

    expect(find.text('Store / buying address'), findsOneWidget);
    expect(find.text('Pin pickup location'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField),
      'Mercury Drug, Main Street',
    );
    await tester.pump();
    expect(
      container.read(manualOrderProvider).pickupLocationName,
      'Mercury Drug, Main Street',
    );
    expect(container.read(manualOrderProvider).hasPickupLocation, isFalse);

    // The map picker saves the address and exact coordinates together.
    container
        .read(manualOrderProvider.notifier)
        .setPickupLocation(
          'Mercury Drug, Main Street, CDO',
          8.454321,
          124.631234,
        );
    await tester.pump();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'Mercury Drug, Main Street, CDO',
    );
    expect(find.text('Edit pickup pin'), findsOneWidget);
    expect(find.textContaining('8.454321, 124.631234'), findsOneWidget);
    expect(container.read(manualOrderProvider).hasPickupLocation, isTrue);

    await tester.enterText(find.byType(TextFormField), 'Another store');
    await tester.pump();
    final changed = container.read(manualOrderProvider);
    expect(changed.pickupLocationName, 'Another store');
    expect(changed.hasPickupLocation, isFalse);
    expect(changed.pickupLat, isNull);
    expect(changed.pickupLng, isNull);
    expect(find.text('Pin pickup location'), findsOneWidget);
    expect(find.textContaining('Pickup pin saved'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved pickup restores on reopening and clears with the order', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(manualOrderProvider.notifier);
    notifier.setPickupLocation('Store A', 8.45, 124.63);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: ManualPickupSection())),
      ),
    );

    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'Store A',
    );
    expect(find.text('Edit pickup pin'), findsOneWidget);
    notifier.clearAll();
    await tester.pump();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      isEmpty,
    );
    expect(find.text('Pin pickup location'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'editing address keeps shopping items and requires pin confirmation',
    () {
      final notifier = ManualOrderNotifier();
      addTearDown(notifier.dispose);
      notifier.addItem('Rice', '', 2);
      notifier.confirmItems();
      notifier.setPickupLocation('Store A', 8.45, 124.63);
      notifier.setPickupAddress('Store B');
      expect(notifier.state.confirmedItems.single.name, 'Rice');
      expect(notifier.state.hasPickupLocation, isFalse);
      notifier.setPickupLocation('Store B', 8.46, 124.64);
      expect(notifier.state.hasPickupLocation, isTrue);
      expect(notifier.state.pickupLat, 8.46);
      expect(notifier.state.pickupLng, 124.64);
      notifier.setPickupAddress('  Store B  ');
      expect(notifier.state.hasPickupLocation, isTrue);
    },
  );
}
