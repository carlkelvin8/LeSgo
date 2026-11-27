import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/data/data_source/dto/partner/partner_dto.dart';

void main() {
  test('per-branch store card keeps the store id and carries the branch', () {
    final card = PartnerDto.fromJson({
      'id': 7,
      'name': 'Kape Co – Urdaneta branch',
      'branch_id': '12',
      'address': 'Siwhwnais, Urdaneta, Pangasinan',
    });

    expect(card.id, 7);
    expect(card.branchId, 12);
    expect(card.address, 'Siwhwnais, Urdaneta, Pangasinan');
  });

  test('older servers send no branch_id and the card stays a plain store', () {
    final card = PartnerDto.fromJson({'id': 7, 'name': 'Kape Co'});

    expect(card.branchId, isNull);
    expect(card.address, isNull);
  });
}
