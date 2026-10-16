import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/data/data_source/order_remote_datasource.dart';
import 'package:lesgo/data/data_source/partner_remote_datasource.dart';
import 'package:lesgo/data/data_source/voucher_remote_datasource.dart';
import 'package:lesgo/data/data_source/dto/partner/partner_dto.dart';
import 'package:lesgo/domain/entities/booking/leseat/order.dart';
import 'package:lesgo/presentation/provider/main/booking/checkout_provider.dart';
import 'package:lesgo/presentation/provider/main/booking/restaurant_detail_provider.dart';

class Partners implements PartnerRemoteDataSource {
  bool configured = false;
  int calls = 0;
  @override
  Future<PartnerDto> getPartner(int id) async {
    calls++;
    return PartnerDto(id: id, name: 'Store',
      latitude: configured ? 18.6058 : null,
      longitude: configured ? 121.0779 : null);
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class Orders implements OrderRemoteDataSource {
  int calls = 0;
  @override
  Future<double?> getFareEstimateRaw({required int serviceId,
    required int estimatedDistanceM, required double pickupLat,
    required double pickupLng, required double dropoffLat,
    required double dropoffLng, String? vehicleType}) async {
    calls++;
    return 45;
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class Vouchers implements VoucherRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class Restaurant extends RestaurantDetailNotifier {
  Restaurant() { state = RestaurantDetailState(activeRestaurantId: '37'); }
}
class Checkout extends CheckoutNotifier {
  Checkout(super.ref) {
    state = CheckoutState(
      order: Order(id: 'cart', restaurantName: 'Store', deliveryAddress: 'Home',
        items: const [], subtotal: 0, deliveryFee: 0),
      dropoffLat: 18.61, dropoffLng: 121.08, hasValidDropoffLocation: true);
  }
}
final subject = StateNotifierProvider<Checkout, CheckoutState>((ref) => Checkout(ref));
void main() {
  test('retry recovers after missing restaurant pickup pin is configured', () async {
    final partners = Partners();
    final orders = Orders();
    getIt.registerSingleton<PartnerRemoteDataSource>(partners);
    getIt.registerSingleton<OrderRemoteDataSource>(orders);
    getIt.registerSingleton<VoucherRemoteDataSource>(Vouchers());
    final container = ProviderContainer(overrides: [
      restaurantDetailProvider.overrideWith((ref) => Restaurant()),
    ]);
    addTearDown(() async { container.dispose(); await getIt.reset(); });
    final notifier = container.read(subject.notifier);
    await notifier.refreshDeliveryFee();
    expect(container.read(subject).hasValidDeliveryFee, isFalse);
    expect(container.read(subject).fareError, contains('pickup location'));
    expect(orders.calls, 0);
    partners.configured = true;
    await notifier.refreshDeliveryFee();
    expect(partners.calls, 2);
    expect(orders.calls, 1);
    expect(container.read(subject).hasValidDeliveryFee, isTrue);
    expect(container.read(subject).order!.deliveryFee, 45);
    expect(container.read(subject).fareError, isNull);
  });
}
