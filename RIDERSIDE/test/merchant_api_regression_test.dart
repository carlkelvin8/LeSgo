import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lezgo_rider/data/data_source/merchant_remote_datasource.dart';
import 'package:lezgo_rider/presentation/provider/main/merchantside/merchant_staff_provider.dart';

Dio fakeDio(Object Function(RequestOptions) reply) {
  final dio = Dio(BaseOptions(baseUrl: 'https://merchant.test/api'));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
    try {
      handler.resolve(Response(requestOptions: request, data: reply(request), statusCode: 200));
    } catch (_) {
      handler.reject(DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 500, data: {'message': 'Server error'}),
        type: DioExceptionType.badResponse,
      ));
    }
  }));
  return dio;
}

Map<String, dynamic> order(int id) => {
  'id': id, 'customer_id': 10, 'service_id': 3, 'status': 'completed',
};

void main() {
  test('merchant menu retains unavailable items in inactive categories', () async {
    final source = MerchantRemoteDataSource(dio: fakeDio((request) {
      expect(request.path, '/v1/partners/7/merchant-menu');
      return {'data': {'categories': [
        {'id': 4, 'partner_id': 7, 'name': 'Hidden meals', 'is_active': false,
          'available_items': [
            {'id': 8, 'partner_id': 7, 'menu_category_id': 4, 'name': 'Sold out meal',
              'price': 100, 'is_available': false},
          ]},
      ]}};
    }));
    final menu = await source.getMerchantMenu(7);
    expect(menu.categories.single.isActive, false);
    expect(menu.categories.single.availableItems!.single.isAvailable, false);
    expect((await source.getMenuItems(7)).single.id, 8);
  });

  test('merchant menu errors are surfaced instead of returning a partial public menu', () async {
    final source = MerchantRemoteDataSource(dio: fakeDio((_) => throw Exception('offline')));
    await expectLater(source.getMerchantMenu(7), throwsException);
  });

  test('order history follows all pages and deduplicates orders', () async {
    final pages = <int>[];
    final source = MerchantRemoteDataSource(dio: fakeDio((request) {
      final page = request.queryParameters['page'] as int;
      pages.add(page);
      expect(request.queryParameters['partner_id'], 7);
      return {
        'data': page == 1 ? [order(3), order(2)] : [order(2), order(1)],
        'meta': {'current_page': page, 'last_page': 2},
      };
    }));
    final orders = await source.getPartnerOrders(7);
    expect(pages, [1, 2]);
    expect(orders.map((o) => o.id), [3, 2, 1]);
  });

  test('legacy nested pagination is supported', () async {
    final source = MerchantRemoteDataSource(dio: fakeDio((request) {
      final page = request.queryParameters['page'] as int;
      return {'data': {'data': [order(page)], 'current_page': page, 'last_page': '2'}};
    }));
    expect((await source.getPartnerOrders(7)).length, 2);
  });

  test('failed later page does not silently return incomplete sales history', () async {
    final source = MerchantRemoteDataSource(dio: fakeDio((request) {
      if (request.queryParameters['page'] == 2) throw Exception('offline');
      return {'data': [order(1)], 'meta': {'last_page': 2}};
    }));
    await expectLater(source.getPartnerOrders(7), throwsException);
  });

  test('staff update and removal release loading state on request failures', () async {
    final notifier = MerchantStaffNotifier(
      dio: fakeDio((_) => throw Exception('offline')),
      loadUser: () async => {'data': {'partner_id': 7}},
    );
    addTearDown(notifier.dispose);
    expect(await notifier.updateStaff(9, isActive: false), false);
    expect(notifier.state.isLoading, false);
    expect(notifier.state.error, isNotNull);
    expect(await notifier.removeStaff(9), false);
    expect(notifier.state.isLoading, false);
  });

  test('staff actions report missing partner and clear loading', () async {
    final notifier = MerchantStaffNotifier(loadUser: () async => {'data': {}});
    addTearDown(notifier.dispose);
    expect(await notifier.updateStaff(9, role: 'cook'), false);
    expect(notifier.state.isLoading, false);
    expect(notifier.state.error, contains('partner ID'));
    expect(await notifier.removeStaff(9), false);
    expect(notifier.state.isLoading, false);
  });

  test('staff actions resolve current account rather than retaining the previous store', () async {
    var partnerId = 7;
    final requestedPaths = <String>[];
    final notifier = MerchantStaffNotifier(
      dio: fakeDio((request) { requestedPaths.add(request.path); return {'data': []}; }),
      loadUser: () async => {'data': {'partner_id': partnerId}},
    );
    addTearDown(notifier.dispose);
    await notifier.loadStaff();
    partnerId = 8;
    await notifier.loadStaff();
    expect(requestedPaths, ['/v1/partners/7/staff', '/v1/partners/8/staff']);
  });
}
