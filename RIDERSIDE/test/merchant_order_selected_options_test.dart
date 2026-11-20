import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/data/data_source/dto/merchant/order_dto.dart';

Map<String, dynamic> _order(Object? selectedOptions) => {
      'id': 1,
      'customer_id': 2,
      'service_id': 3,
      'lesbuy_items': [
        {
          'id': 10,
          'order_id': 1,
          'name': 'Plain rice',
          'quantity': 1,
          'selected_options': selectedOptions,
        },
      ],
    };

void main() {
  test('an item without options does not break the orders list', () {
    // PHP encodes an item with no options as an empty list, not an object.
    final order = OrderDto.fromJson(_order(<dynamic>[]));

    expect(order.orderItems!.single.selectedOptionsRaw, isNull);
    expect(order.orderItems!.single.selectedOptions.addons, isEmpty);
  });

  test('selected options still parse when present', () {
    final order = OrderDto.fromJson(_order({
      'size': {'label': 'Large', 'price': 20},
    }));

    expect(order.orderItems!.single.selectedOptions.size?.label, 'Large');
  });

  test('missing selected options stay null', () {
    final order = OrderDto.fromJson(_order(null));

    expect(order.orderItems!.single.selectedOptionsRaw, isNull);
  });
}
