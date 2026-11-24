import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/utils/ph_address.dart';
import 'package:lesgo/presentation/widgets/location/address_details_sheet.dart';

Future<PhAddress?> Function() _open(WidgetTester tester, PhAddress initial) {
  PhAddress? result;
  var done = false;
  return () async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await AddressDetailsSheet.show(context, initial: initial);
                done = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return done ? result : null;
  };
}

void main() {
  const cityOnly = PhAddress(city: 'City of San Jose del Monte', province: 'Bulacan');

  testWidgets('a city-only pin asks for more and blocks confirming without a barangay', (tester) async {
    await _open(tester, cityOnly)();
    expect(find.textContaining('could only find the city'), findsOneWidget);

    await tester.tap(find.text('Confirm address'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your barangay'), findsOneWidget);
    expect(find.byType(AddressDetailsSheet), findsOneWidget, reason: 'stays open');
  });

  testWidgets('the customer completes block, lot, street, subdivision, barangay and zip', (tester) async {
    PhAddress? out;
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  out = await AddressDetailsSheet.show(context, initial: cityOnly),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    Future<void> type(String label, String text) async {
      await tester.enterText(find.widgetWithText(TextFormField, label), text);
      await tester.pump();
    }

    await type('Block', '14');
    await type('Lot', '9');
    await type('Street', 'Mahogany Street');
    await type('Subdivision / Village / Building', 'Francisco Homes');
    await type('Barangay', 'Muzon');
    await type('ZIP code', '3023');

    // The "rider will see" preview updates live.
    expect(
      find.text(
        'Blk 14 Lot 9, Mahogany Street, Francisco Homes, Brgy. Muzon, City of San Jose del Monte, Bulacan 3023',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('could only find the city'), findsNothing);

    await tester.tap(find.text('Confirm address'));
    await tester.pumpAndSettle();

    expect(out, isNotNull);
    expect(out!.block, '14');
    expect(out!.lot, '9');
    expect(out!.barangay, 'Muzon');
    expect(out!.zip, '3023');
    expect(out!.city, 'City of San Jose del Monte');
  });

  testWidgets('what the map already found is pre-filled', (tester) async {
    await _open(
      tester,
      const PhAddress(
        street: 'Mahogany Street',
        barangay: 'Muzon',
        city: 'San Jose del Monte',
        province: 'Bulacan',
        zip: '3023',
      ),
    )();
    expect(find.text('Mahogany Street'), findsWidgets);
    expect(find.textContaining('could only find the city'), findsNothing);
    final zip = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'ZIP code'));
    expect(zip.controller!.text, '3023');
  });

  testWidgets('a ZIP must be 4 digits', (tester) async {
    await _open(tester, const PhAddress(street: 'X', barangay: 'Muzon', city: 'SJDM'))();
    await tester.enterText(find.widgetWithText(TextFormField, 'ZIP code'), '30');
    await tester.tap(find.text('Confirm address'));
    await tester.pumpAndSettle();
    expect(find.text('4 digits'), findsOneWidget);
  });

  for (final c in [(320.0, 1.0), (320.0, 2.0)]) {
    testWidgets('no overflow at ${c.$1}px / ${c.$2}x text', (tester) async {
      tester.view.physicalSize = Size(c.$1, 900);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = c.$2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => AddressDetailsSheet.show(context, initial: cityOnly),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
