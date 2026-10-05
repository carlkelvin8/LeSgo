import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// The platform interface shipped with google_maps_flutter lets this test keep
// the native map offline while exercising its real tap/search/drag callbacks.
// ignore: depend_on_referenced_packages
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:lesgo/core/utils/lesbuy_manual_delivery_utils.dart';
import 'package:lesgo/data/data_source/dto/address/address_dto.dart';
import 'package:lesgo/presentation/provider/main/address/address_provider.dart';
import 'package:lesgo/presentation/provider/main/booking/lesbuy/manual_order_provider.dart';
import 'package:lesgo/presentation/widgets/booking/lesbuy/manual_order/manual_pickup_section.dart';
import 'package:lesgo/presentation/widgets/global/googlemaps/map_search_bar.dart';

class _OfflineMap extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) => const SizedBox.expand();
}

AddressDto delivery({
  String address = 'Customer home',
  double lat = 14.72,
  double lng = 121.04,
}) => AddressDto(
  id: 1,
  userId: 1,
  label: 'Home',
  addressLine1: address,
  country: 'PH',
  latitude: lat,
  longitude: lng,
  isDefault: true,
  createdAt: '',
  updatedAt: '',
);

void main() {
  test('manual checkout requires a delivery address and real pin', () {
    expect(LesbuyManualDeliveryUtils.hasDeliveryLocation(null), isFalse);
    expect(
      LesbuyManualDeliveryUtils.hasDeliveryLocation(delivery(address: '  ')),
      isFalse,
    );
    expect(
      LesbuyManualDeliveryUtils.hasDeliveryLocation(delivery(lat: 0, lng: 0)),
      isFalse,
    );
    expect(
      LesbuyManualDeliveryUtils.hasDeliveryLocation(delivery(lat: double.nan)),
      isFalse,
    );
    expect(
      LesbuyManualDeliveryUtils.hasDeliveryLocation(delivery(lat: 91)),
      isFalse,
    );
    expect(LesbuyManualDeliveryUtils.hasDeliveryLocation(delivery()), isTrue);
  });

  setUp(() {
    final original = GoogleMapsFlutterPlatform.instance;
    GoogleMapsFlutterPlatform.instance = _OfflineMap();
    addTearDown(() => GoogleMapsFlutterPlatform.instance = original);
  });

  Future<ProviderContainer> mount(
    WidgetTester tester, {
    bool existing = false,
  }) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(addressProvider.notifier).selectAddress(delivery());
    if (existing) {
      container
          .read(manualOrderProvider.notifier)
          .setPickupLocation('Old store', 14.73, 121.05);
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ManualPickupScreen(),
                  ),
                ),
                child: const Text('Choose store'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Choose store'));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    'store search and dragged pin save pickup only; address alone cannot save',
    (tester) async {
      final container = await mount(tester);
      expect(tester.widget<GoogleMap>(find.byType(GoogleMap)).markers, isEmpty);
      await tester.enterText(
        find.byType(TextFormField),
        'SM Fairview, Quirino Highway, Quezon City',
      );
      await tester.tap(find.text('Save pickup point'));
      await tester.pump();
      expect(
        find.text('Tap the map to set the store pickup pin.'),
        findsOneWidget,
      );
      expect(container.read(manualOrderProvider).hasPickupLocation, isFalse);
      final search = tester.widget<MapSearchBar>(find.byType(MapSearchBar));
      expect(search.showSavedAddresses, isFalse);
      search.onPlaceSelected(
        const LatLng(14.735, 121.057),
        'SM Fairview, Quirino Highway, Quezon City',
        {},
      );
      await tester.pump();
      var map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.markers.single.position, const LatLng(14.735, 121.057));
      map.markers.single.onDragEnd!(const LatLng(14.736, 121.058));
      await tester.pump();
      await tester.tap(find.text('Save pickup point'));
      await tester.pumpAndSettle();
      final order = container.read(manualOrderProvider);
      expect(
        order.pickupLocationName,
        'SM Fairview, Quirino Highway, Quezon City',
      );
      expect(order.pickupLat, 14.736);
      expect(order.pickupLng, 121.058);
      expect(
        container.read(addressProvider).deliveryAddress!.addressLine1,
        'Customer home',
      );
      expect(container.read(addressProvider).deliveryAddress!.latitude, 14.72);
      await tester.tap(find.text('Choose store'));
      await tester.pumpAndSettle();
      map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.markers.single.position, const LatLng(14.736, 121.058));
    },
  );

  testWidgets(
    'changing the store invalidates old pin; cancelling preserves saved pickup',
    (tester) async {
      final container = await mount(tester, existing: true);
      await tester.enterText(find.byType(TextFormField), 'New store');
      await tester.pump();
      expect(tester.widget<GoogleMap>(find.byType(GoogleMap)).markers, isEmpty);
      await tester.tap(find.text('Save pickup point'));
      await tester.pump();
      expect(find.byType(ManualPickupScreen), findsOneWidget);
      expect(
        container.read(manualOrderProvider).pickupLocationName,
        'Old store',
      );
      tester.widget<GoogleMap>(find.byType(GoogleMap)).onTap!(
        const LatLng(14.74, 121.06),
      );
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        container.read(manualOrderProvider).pickupLocationName,
        'Old store',
      );
      expect(container.read(manualOrderProvider).pickupLat, 14.73);
      expect(container.read(addressProvider).deliveryAddress!.latitude, 14.72);
    },
  );
}
