import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/utils/address_utils.dart';

void main() {
  test('strips leading plus code', () {
    expect(stripPlusCode('9JGQ+2X Claveria, Cagayan'), 'Claveria, Cagayan');
    expect(stripPlusCode('7M2PM3F8+5X, Manila, Philippines'),
        'Manila, Philippines');
  });

  test('leaves normal addresses untouched', () {
    expect(stripPlusCode('Rizal St, Claveria'), 'Rizal St, Claveria');
  });

  test('keeps address if only a plus code', () {
    expect(stripPlusCode('9JGQ+2X'), '9JGQ+2X');
  });
}
