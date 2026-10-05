import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/utils/lesbuy_pickup_selection.dart';
import 'package:lesgo/data/data_source/dto/order/create_order_request_dto.dart';

void main() {
  final store = OrderAddressDto(address: 'Store', lat: 8.5, lng: 124.5);
  final manual = OrderAddressDto(address: 'Buy here', lat: 8.45, lng: 124.63);
  final delivery = OrderAddressDto(address: 'Deliver here', lat: 8.48, lng: 124.65);
  test('manual pickup survives actual checkout selection and serialization', () {
    final selected = LesbuyPickupSelection.select(hasStoreItems: false,
      hasManualItems: true, store: store, manual: manual);
    final payload = jsonDecode(jsonEncode(CreateOrderRequestDto(serviceId: 4, estimatedDistanceM: 1000, pickup: selected,
      dropoff: delivery, paymentMethod: 'cash').toJson()));
    expect(payload['pickup'], manual.toJson());
    expect(payload['dropoff'], delivery.toJson());
  });
  test('store-only cart uses merchant pickup', () {
    expect(LesbuyPickupSelection.select(hasStoreItems: true,
      hasManualItems: false, store: store, manual: manual), same(store));
  });
  test('mixed cart cannot discard the manually chosen buying point', () {
    expect(() => LesbuyPickupSelection.select(hasStoreItems: true,
      hasManualItems: true, store: store, manual: manual), throwsStateError);
    expect(manual.address, 'Buy here');
    expect(manual.lat, 8.45);
    expect(manual.lng, 124.63);
  });
  test('missing manual pin cannot fall back to store coordinates', () {
    expect(() => LesbuyPickupSelection.select(hasStoreItems: false,
      hasManualItems: true, store: store), throwsStateError);
  });
}
