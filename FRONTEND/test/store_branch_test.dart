import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/data/data_source/dto/partner/store_branch.dart';

void main() {
  StoreBranch branch(int id, double lat, double lng, {bool open = true}) =>
      StoreBranch(id: id, name: 'B$id', address: '', latitude: lat, longitude: lng, isOpen: open);

  test('parses API branch with joined address and string coordinates', () {
    final b = StoreBranch.fromJson({
      'id': '7',
      'name': 'Katipunan',
      'address_line1': '300 Katipunan Ave',
      'city': 'Quezon City',
      'latitude': '14.6392',
      'longitude': '121.0770',
      'is_primary': 1,
      'is_open': true,
    });
    expect(b.id, 7);
    expect(b.address, '300 Katipunan Ave, Quezon City');
    expect(b.latitude, closeTo(14.6392, 1e-6));
    expect(b.isPrimary, isTrue);
  });

  test('orderableNearest drops closed or unpinned branches and sorts by distance', () {
    final far = branch(1, 14.40, 121.00);
    final near = branch(2, 14.6085, 121.0005);
    final closed = branch(3, 14.6090, 121.0000, open: false);
    const unpinned = StoreBranch(id: 4, name: 'No pin', address: '');

    final result = StoreBranch.orderableNearest([far, near, closed, unpinned], 14.6090, 121.0000);

    expect(result.map((b) => b.id), [2, 1]);
  });
}
