import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/utils/address_text_utils.dart';
import 'package:lesgo/data/data_source/dto/partner/store_branch.dart';

void main() {
  group('joinAddressParts', () {
    test('drops repeated segments (Jollibee Claveria sample)', () {
      expect(
        joinAddressParts(['Claveria, Cagayan', null, 'Claveria', 'Cagayan Valley']),
        'Claveria, Cagayan, Cagayan Valley',
      );
    });

    test('skips null, blank and case-insensitive duplicates', () {
      expect(
        joinAddressParts(['Centro I', '  ', null, 'claveria', 'CLAVERIA', 'Cagayan Valley']),
        'Centro I, claveria, Cagayan Valley',
      );
    });

    test('keeps distinct parts in order and handles empty input', () {
      expect(joinAddressParts(['300 Katipunan Ave', 'Quezon City']), '300 Katipunan Ave, Quezon City');
      expect(joinAddressParts([null, '', ' ']), '');
    });
  });

  test('StoreBranch.fromJson does not repeat city/province in the address', () {
    final b = StoreBranch.fromJson({
      'id': 1,
      'name': 'Jollibee - Claveria (Main)',
      'address_line1': 'Claveria, Cagayan',
      'city': 'Claveria',
      'region': 'Cagayan Valley',
    });
    expect(b.address, 'Claveria, Cagayan, Cagayan Valley');
  });
}
