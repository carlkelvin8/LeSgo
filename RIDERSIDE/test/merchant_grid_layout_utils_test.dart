import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/core/utils/merchant_grid_layout_utils.dart';

void main() {
  test('merchant menu cards get extra height on phone screens', () {
    expect(merchantMenuCardAspectRatio(393), 0.50);
    expect(merchantMenuCardAspectRatio(834), 0.72);
  });

  test('Book cards reserve enough height for narrow phone cards', () {
    expect(merchantBookCardAspectRatio(393), 0.58);
    expect(merchantBookCardAspectRatio(834), 0.72);
  });
}
