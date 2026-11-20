import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/data/data_source/address_remote_datasource.dart';
import 'package:lesgo/data/data_source/order_remote_datasource.dart';
import 'package:lesgo/data/data_source/partner_remote_datasource.dart';
import 'package:lesgo/data/data_source/voucher_remote_datasource.dart';
import 'package:lesgo/domain/use_cases/login_usecase.dart';
import 'package:lesgo/domain/use_cases/logout_usecase.dart';
import 'package:lesgo/core/di/local_storage_service.dart';
import 'package:lesgo/presentation/provider/auth/auth_provider.dart';
import 'package:lesgo/presentation/provider/main/address/address_provider.dart';
import 'package:lesgo/presentation/provider/main/booking/checkout_provider.dart';
import 'package:lesgo/presentation/provider/main/profile/profile_provider.dart';
import 'package:lesgo/presentation/screens/main/booking/leseat/leseat_checkout_screen.dart';
import 'manual_pickup_map_test.dart' show delivery;

class _Orders implements OrderRemoteDataSource {
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

class _Addresses implements AddressRemoteDataSource {
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

class _Profile extends ProfileNotifier {
  @override
  Future<void> loadProfile() async {}
}

void main() {
  testWidgets(
    'checkout without an address prompts once, then adopts an address added later',
    (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      getIt.registerSingleton<OrderRemoteDataSource>(_Orders());
      getIt.registerSingleton<PartnerRemoteDataSource>(_Partners());
      getIt.registerSingleton<VoucherRemoteDataSource>(_Vouchers());
      getIt.registerSingleton<AddressRemoteDataSource>(_Addresses());
      addTearDown(getIt.reset);

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((_) => _Profile()),
          authProvider.overrideWith((_) => AuthNotifier(_Login(), _Logout(), _Storage())),
        ],
      );
      addTearDown(container.dispose);
      await container.read(checkoutProvider.notifier).initializeFromCart('Jollibee');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LeseatCheckoutScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // No address: the card prompts, and the address sheet opened by itself.
      expect(find.text('Add a delivery address'), findsWidgets);
      expect(find.text('Select Delivery Address'), findsOneWidget);
      expect(container.read(checkoutProvider).hasValidDropoffLocation, isFalse);

      // An address becomes available (e.g. added via Manage > Add Address).
      container.read(addressProvider.notifier).selectAddress(delivery(address: 'Centro I, Claveria'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final state = container.read(checkoutProvider);
      expect(state.hasValidDropoffLocation, isTrue, reason: 'checkout adopts the new address');
      expect(state.order!.deliveryAddress, 'Centro I, Claveria');
    },
  );
}
