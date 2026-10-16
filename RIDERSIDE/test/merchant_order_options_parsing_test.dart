import 'package:flutter_test/flutter_test.dart';
import '../lib/data/data_source/dto/merchant/order_dto.dart';

Map<String, dynamic> orderPayload(dynamic options) => {
  'id': 101,
  'customer_id': 20,
  'service_id': 3,
  'partner_id': 37,
  'lesbuy_items': [
    {'id': 1, 'order_id': 101, 'name': 'Meal', 'quantity': 1,
      'estimated_price': '123.00', 'selected_options': options},
  ],
};

void main() {
  test('Laravel empty options array does not prevent loading an order', () {
    final order = OrderDto.fromJson(orderPayload([]));
    expect(order.id, 101);
    expect(order.orderItems!.single.selectedOptions.isEmpty, isTrue);
    expect(order.orderItems!.single.unitPrice, 123);
  });

  test('object options and null options remain supported', () {
    final options = {'size': 'Large'};
    final order = OrderDto.fromJson(orderPayload(options));
    expect(order.orderItems!.single.selectedOptionsRaw, options);
    expect(OrderDto.fromJson(orderPayload(null)).orderItems!.single.selectedOptionsRaw, isNull);
  });

  test('invalid non-empty arrays are not silently discarded', () {
    expect(() => OrderDto.fromJson(orderPayload(['bad'])), throwsFormatException);
  });
}
