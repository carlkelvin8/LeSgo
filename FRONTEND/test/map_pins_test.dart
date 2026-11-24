import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/utils/map_pins.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every pin falls back to a default marker before it is loaded', () {
    for (final k in MapPinKind.values) {
      expect(MapPins.icon(k), isNotNull);
    }
  });

  testWidgets('the customer, rider, store and destination pins all load', (
    tester,
  ) async {
    await tester.runAsync(() => MapPins.preload(devicePixelRatio: 2));
    expect(MapPins.isReady, isTrue);
  });
}
