import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/data/data_source/address_remote_datasource.dart';
import 'package:lesgo/data/data_source/dto/address/address_dto.dart';
import 'package:lesgo/data/data_source/dto/address/address_response_dto.dart';
import 'package:lesgo/data/data_source/dto/address/addresses_response_dto.dart';
import 'package:lesgo/data/data_source/dto/address/delete_address_response_dto.dart';
import 'package:lesgo/data/data_source/dto/address/update_address_request_dto.dart';
import 'package:lesgo/presentation/provider/main/address/address_provider.dart';

AddressDto _addr(int id, {bool isDefault = false, int day = 1}) => AddressDto(
  id: id,
  userId: 1,
  label: 'A$id',
  addressLine1: 'Street $id',
  country: 'Philippines',
  latitude: 14.5,
  longitude: 121.0,
  isDefault: isDefault,
  createdAt: '2026-01-0${day}T00:00:00Z',
  updatedAt: '2026-01-0${day}T00:00:00Z',
);

class _FakeAddressApi implements AddressRemoteDataSource {
  List<AddressDto> server;
  final List<int> defaultCalls = [];
  _FakeAddressApi(this.server);

  @override
  Future<AddressesResponseDto> getAddresses() async =>
      AddressesResponseDto(success: true, data: List.of(server));

  @override
  Future<DeleteAddressResponseDto> deleteAddress(int id) async {
    server = server.where((a) => a.id != id).toList();
    return DeleteAddressResponseDto(success: true);
  }

  @override
  Future<AddressResponseDto> updateAddress(
    int id,
    UpdateAddressRequestDto request,
  ) async {
    if (request.isDefault == true) {
      defaultCalls.add(id);
      server = [for (final a in server) _addr(a.id, isDefault: a.id == id)];
    }
    return AddressResponseDto(
      success: true,
      data: server.firstWhere((a) => a.id == id),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeAddressApi api;
  late AddressNotifier notifier;

  void setUpApi(List<AddressDto> server) {
    api = _FakeAddressApi(server);
    getIt.registerSingleton<AddressRemoteDataSource>(api);
    notifier = AddressNotifier();
  }

  tearDown(() {
    notifier.dispose();
    getIt.unregister<AddressRemoteDataSource>();
  });

  test('deleting the last address clears the delivery address', () async {
    setUpApi([_addr(1, isDefault: true)]);
    await notifier.loadAddresses(1);
    expect(notifier.state.deliveryAddress?.id, 1);

    await notifier.deleteAddress(userId: 1, addressId: 1);

    expect(notifier.state.addresses, isEmpty);
    expect(notifier.state.selectedAddress, isNull);
    expect(notifier.state.deliveryAddress, isNull);
  });

  test('clearSelectedAddress actually clears the selection', () async {
    setUpApi([_addr(1, isDefault: true)]);
    await notifier.loadAddresses(1);
    notifier.clearSelectedAddress();
    expect(notifier.state.selectedAddress, isNull);
  });

  test('set as default changes the delivery address', () async {
    setUpApi([_addr(1, isDefault: true), _addr(2)]);
    await notifier.loadAddresses(1);
    expect(notifier.state.deliveryAddress?.id, 1);

    await notifier.setAsDefault(userId: 1, addressId: 2);

    expect(notifier.state.deliveryAddress?.id, 2);
    expect(notifier.state.selectedAddress?.id, 2);
  });

  test('an explicit selection survives reloads', () async {
    setUpApi([_addr(1, isDefault: true), _addr(2)]);
    await notifier.loadAddresses(1);
    notifier.selectAddress(_addr(2));
    await notifier.loadAddresses(1);
    expect(notifier.state.deliveryAddress?.id, 2);
  });

  test('deleting the default promotes the fallback on the server', () async {
    setUpApi([_addr(1, isDefault: true, day: 3), _addr(2, day: 2)]);
    await notifier.loadAddresses(1);

    await notifier.deleteAddress(userId: 1, addressId: 1);

    expect(api.defaultCalls, [2]);
    expect(notifier.state.defaultAddress?.id, 2);
    expect(notifier.state.defaultAddress?.isDefault, isTrue);
    expect(notifier.state.deliveryAddress?.id, 2);
    expect(notifier.state.isDeleting, isFalse);
  });
}
