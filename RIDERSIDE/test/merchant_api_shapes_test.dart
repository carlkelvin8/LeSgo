import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/data/data_source/dto/merchant/menu_item_dto.dart';
import 'package:lezgo_rider/data/data_source/dto/merchant/partner_dto.dart';
import 'package:lezgo_rider/data/data_source/dto/merchant/review_dto.dart';
import 'package:lezgo_rider/data/data_source/merchant_remote_datasource.dart';
import 'package:lezgo_rider/presentation/provider/cart/cart_provider.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_food_detail_provider.dart';
import 'package:lezgo_rider/presentation/screens/main/merchantside/views/merchant_book_view.dart';

void main() {
  test('empty opening hours do not break the partner profile', () {
    final partner = PartnerDto.fromJson({'id': 1, 'user_id': 2, 'name': 'Store', 'opening_hours': <dynamic>[]});

    expect(partner.openingHours, isNull);
  });

  test('empty item options do not break the menu', () {
    final item = MenuItemDto.fromJson({
      'id': 1, 'partner_id': 1, 'menu_category_id': 1, 'name': 'Rice', 'price': '50.00',
      'options': <dynamic>[],
    });

    expect(item.options, isNull);
  });

  test('a review reads the columns the API actually returns', () {
    final review = ReviewDto.fromJson({'id': 7, 'user_id': 3, 'overall_rating': 5, 'review_comment': 'Good'});

    expect(review.rating, 5);
    expect(review.comment, 'Good');
  });

  test('sizes stored as choices keep their label and price', () {
    expect(
      bookItemSizes({
        'sizes': [
          {'label': 'Large', 'price': '10.00'},
        ],
      }),
      [const MerchantFoodSizeOption(label: 'Large', price: 10)],
    );
    expect(bookItemSizes(null), isEmpty);
    expect(bookItemSizes({'sizes': <dynamic>[]}), isEmpty);
  });

  test('a chosen size adds its price and an order line sends it', () {
    final notifier = MerchantFoodDetailNotifier(
      input: const MerchantFoodDetailInput(
        foodName: 'Tea',
        price: 'PHP 40.00',
        sizes: [
          MerchantFoodSizeOption(label: 'Small'),
          MerchantFoodSizeOption(label: 'Large', price: 20),
        ],
      ),
    );
    addTearDown(notifier.dispose);

    expect(notifier.state.unitPrice, 40);
    notifier.selectSize(const MerchantFoodSizeOption(label: 'Large', price: 20));
    expect(notifier.state.unitPrice, 60);

    final cart = CartNotifier();
    addTearDown(cart.dispose);
    cart.addItem(
      name: 'Tea',
      size: 'Large',
      unitPrice: 60,
      menuItemId: 1,
      selectedOptions: {
        'size': {'label': 'Large', 'price': 20.0},
      },
    );
    expect(cart.state.items.single.selectedOptions?['size']?['label'], 'Large');
  });

  test('flavors and add-ons add their prices and are sent for the server to re-price', () {
    final notifier = MerchantFoodDetailNotifier(
      input: const MerchantFoodDetailInput(
        foodName: 'Cake',
        price: 'PHP 100.00',
        sizes: [],
        flavors: [
          MerchantFoodSizeOption(label: 'Vanilla'),
          MerchantFoodSizeOption(label: 'Mocha', price: 15),
        ],
        addons: [
          MerchantFoodSizeOption(label: 'Extra cream', price: 10),
          MerchantFoodSizeOption(label: 'Nuts', price: 5),
        ],
      ),
    );
    addTearDown(notifier.dispose);

    expect(notifier.state.selectedFlavor?.label, 'Vanilla');
    expect(notifier.state.unitPrice, 100);
    notifier.selectFlavor(const MerchantFoodSizeOption(label: 'Mocha', price: 15));
    notifier.toggleAddon(const MerchantFoodSizeOption(label: 'Extra cream', price: 10));
    notifier.toggleAddon(const MerchantFoodSizeOption(label: 'Nuts', price: 5));
    notifier.toggleAddon(const MerchantFoodSizeOption(label: 'Nuts', price: 5));

    expect(notifier.state.unitPrice, 125);
    expect(notifier.state.optionsLabel, 'Regular, Mocha, + Extra cream');
    expect(notifier.state.selectedOptions, {
      'flavor': {'label': 'Mocha', 'price': 15.0},
      'addons': [
        {'label': 'Extra cream', 'price': 10.0, 'quantity': 1},
      ],
    });
    expect(bookItemFlavors({'flavors': [{'label': 'Mocha', 'price': 15}]}).single.price, 15);
    expect(bookItemAddons({'addons': [{'label': 'Nuts', 'price': '5'}]}).single.label, 'Nuts');
  });

  test('review paging comes from the response meta', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://merchant.test/api'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      handler.resolve(Response(requestOptions: request, statusCode: 200, data: {
        'data': [
          {'id': 1, 'overall_rating': 4},
        ],
        'meta': {'current_page': 1, 'last_page': 3, 'total': 41},
      }));
    }));

    final page = await MerchantRemoteDataSource(dio: dio).getPartnerReviews(1);

    expect(page.lastPage, 3);
    expect(page.total, 41);
    expect(page.reviews.single.rating, 4);
  });
}
