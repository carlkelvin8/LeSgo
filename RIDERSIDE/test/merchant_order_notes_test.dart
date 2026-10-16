import 'package:flutter_test/flutter_test.dart';
import '../lib/core/utils/merchant_order_ops_utils.dart';
import '../lib/data/data_source/dto/merchant/order_dto.dart';

OrderDto withNote(String note) => OrderDto.fromJson({
  'id': 1, 'customer_id': 2, 'service_id': 3, 'notes': note,
});

void main() {
  test('automated LesEat item-count metadata is not shown as an instruction', () {
    for (final note in ['LesEat order: 1 items', 'LesEat order: 1 item', 'LesEat order: 12 items']) {
      expect(MerchantOrderOpsUtils.orderSpecialInstructions(withNote(note)), isNull);
    }
  });

  test('real customer requests and mixed notes are preserved', () {
    for (final note in ['No onions please', 'LesEat order: 1 items. No onions please']) {
      expect(MerchantOrderOpsUtils.orderSpecialInstructions(withNote(note)), note);
    }
  });
}
