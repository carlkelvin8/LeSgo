import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/data/data_source/dto/merchant/menu_item_dto.dart';
import 'package:lezgo_rider/data/data_source/merchant_remote_datasource.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_menu_provider.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/views/merchant_book_view.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/views/merchant_menu_view.dart';

MenuItemDto _item() => MenuItemDto.fromJson({
  'id': 99,
  'partner_id': 5,
  'menu_category_id': 7,
  'name': 'QA Pancake With A Longer Test Name',
  'price': 49,
  'is_available': true,
  'options': {
    '_inventory': {
      'stock': 10,
      'track_stock': true,
      'auto_hide_when_empty': true,
    },
  },
});

MenuResponse _menu() => MenuResponse(
  categories: [
    MenuCategoryDto(
      id: 7,
      partnerId: 5,
      name: 'QA test category',
      availableItems: [_item()],
    ),
  ],
);

Future<void> _pumpGrid(WidgetTester tester, {required Widget screen}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        merchantMenuProvider.overrideWith((ref) async => _menu()),
        merchantMenuItemsProvider.overrideWith((ref) async => [_item()]),
        canEditMerchantMenuProvider.overrideWith((ref) => true),
      ],
      child: MaterialApp(home: Scaffold(body: screen)),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('merchant Menu inventory card fits without overflow', (
    tester,
  ) async {
    await _pumpGrid(tester, screen: const MerchantMenuView());

    expect(find.text('QA Pancake With A Longer Test Name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('merchant Book item card fits without overflow', (tester) async {
    await _pumpGrid(tester, screen: const MerchantBookView());

    expect(find.text('QA Pancake With A Longer Test Name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
