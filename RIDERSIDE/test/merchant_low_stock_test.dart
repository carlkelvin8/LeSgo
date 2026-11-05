import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/data/data_source/dto/merchant/menu_item_dto.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_low_stock_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_menu_provider.dart';

MenuItemDto _item(int id, Map<String, dynamic>? options) => MenuItemDto.fromJson({
      'id': id,
      'partner_id': 1,
      'menu_category_id': 1,
      'name': 'Item $id',
      'price': '100.00',
      'is_available': true,
      'options': options,
    });

void main() {
  test('low stock is read from the inventory block the API returns', () async {
    final container = ProviderContainer(overrides: [
      merchantMenuItemsProvider.overrideWith((ref) async => [
            _item(1, {'_inventory': {'stock': 2, 'track_stock': true}}),
            _item(2, {'_inventory': {'stock': 0, 'track_stock': true}}),
            _item(3, {'_inventory': {'stock': 50, 'track_stock': true}}),
            _item(4, null),
          ]),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(merchantMenuItemsProvider, (_, __) {});
    addTearDown(subscription.close);

    await container.read(merchantMenuItemsProvider.future);

    expect(
      container.read(merchantLowStockItemsProvider).map((item) => item.id),
      [1, 2],
    );
  });
}
