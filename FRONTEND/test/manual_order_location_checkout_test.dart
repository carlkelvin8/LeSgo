import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/di/local_storage_service.dart';
import 'package:lesgo/core/services/connectivity_service.dart';
import 'package:lesgo/core/utils/lesbuy_manual_delivery_utils.dart';
import 'package:lesgo/data/data_source/order_remote_datasource.dart';
import 'package:lesgo/data/data_source/partner_remote_datasource.dart';
import 'package:lesgo/data/data_source/voucher_remote_datasource.dart';
import 'package:lesgo/data/data_source/dto/order/create_order_request_dto.dart';
import 'package:lesgo/data/data_source/dto/order/orders_response_dto.dart';
import 'package:lesgo/domain/use_cases/login_usecase.dart';
import 'package:lesgo/domain/use_cases/logout_usecase.dart';
import 'package:lesgo/presentation/provider/auth/auth_provider.dart';
import 'package:lesgo/presentation/provider/main/address/address_provider.dart';
import 'package:lesgo/presentation/provider/main/profile/profile_provider.dart';
import 'package:lesgo/presentation/provider/main/lespay/lespay_provider.dart';
import 'package:lesgo/presentation/provider/main/booking/lesbuy/manual_order_provider.dart';
import 'package:lesgo/presentation/provider/main/booking/lesbuy/lesbuy_checkout_provider.dart';
import 'package:lesgo/presentation/screens/main/booking/lesbuy/manual_order_screen.dart';
import 'package:lesgo/presentation/screens/main/booking/lesbuy/store_cart_screen.dart';
import 'package:lesgo/presentation/widgets/address/address_selector_widget.dart';
import 'manual_pickup_map_test.dart' show delivery;

class _Orders implements OrderRemoteDataSource {
  CreateOrderRequestDto? submitted;
  @override
  Future<OrdersResponseDto> getOrders({String? status, String? paymentStatus, int? serviceId, int perPage = 20, int page = 1}) async => OrdersResponseDto(success: true, data: []);
  @override
  Future<OrderResponseDto> createOrder(CreateOrderRequestDto request) async {
    submitted = request;
    throw StateError('Offline test stops at the API boundary');
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class _Partners implements PartnerRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class _Vouchers implements VoucherRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class _Login implements LoginUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class _Logout implements LogoutUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class _Storage implements LocalStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class _Online implements ConnectivityService {
  @override
  bool get isConnected => true;
  @override
  Future<bool> checkConnection() async => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class _Profile extends ProfileNotifier {
  @override
  Future<void> loadProfile() async {}
}
class _Wallet extends LespayNotifier {
  @override
  Future<void> refreshBalance() async {}
}
class _Checkout extends LesbuyCheckoutNotifier {
  _Checkout(super.ref);
  @override
  Future<void> initialize({required String? storePartnerId}) async {}
}

void main() {
  for (final cart in [false, true]) {
    testWidgets('manual checkout requires delivery and sends store as pickup (cart=$cart)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final orders = _Orders();
      getIt.registerSingleton<OrderRemoteDataSource>(orders);
      getIt.registerSingleton<PartnerRemoteDataSource>(_Partners());
      getIt.registerSingleton<VoucherRemoteDataSource>(_Vouchers());
      getIt.registerSingleton<ConnectivityService>(_Online());
      addTearDown(getIt.reset);
      final container = ProviderContainer(overrides: [
        profileProvider.overrideWith((_) => _Profile()),
        authProvider.overrideWith((_) => AuthNotifier(_Login(), _Logout(), _Storage())),
        lespayProvider.overrideWith((_) => _Wallet()),
        lesbuyCheckoutProvider.overrideWith((ref) => _Checkout(ref)),
      ]);
      addTearDown(container.dispose);
      final manual = container.read(manualOrderProvider.notifier);
      manual.addItem('Rice', 'Buy at specified shop', 1);
      manual.setPickupLocation('SM Fairview, Quirino Highway, Quezon City', 14.736, 121.058);
      if (cart) manual.confirmItems();
      await tester.pumpWidget(UncontrolledProviderScope(container: container,
        child: MaterialApp(home: cart ? const StoreCartScreen() : const ManualOrderScreen())));
      await tester.pumpAndSettle();
      if (!cart) {
        expect(find.byType(AddressSelectorWidget), findsOneWidget);
      }
      await tester.tap(find.text(cart ? 'Checkout' : 'Checkout Now').last);
      await tester.pumpAndSettle();
      expect(orders.submitted, isNull);
      expect(find.text(LesbuyManualDeliveryUtils.missingDeliveryMessage), findsOneWidget);
      container.read(addressProvider.notifier).selectAddress(delivery());
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text(cart ? 'Checkout' : 'Checkout Now').last);
      await tester.pumpAndSettle();
      final request = orders.submitted!;
      expect(request.pickup.address, 'SM Fairview, Quirino Highway, Quezon City');
      expect(request.pickup.lat, 14.736);
      expect(request.pickup.lng, 121.058);
      expect(request.dropoff.address, 'Customer home');
      expect(request.dropoff.lat, 14.72);
      expect(request.dropoff.lng, 121.04);
      expect(request.items!.single.source, 'manual');
      expect(container.read(manualOrderProvider).hasPickupLocation, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
