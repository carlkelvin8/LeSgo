import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/data/data_source/dto/order/create_order_request_dto.dart';
import 'package:lesgo/domain/entities/booking/booking_service.dart';
import 'package:lesgo/domain/entities/booking/lesride_vehicle_option.dart';
import 'package:lesgo/presentation/provider/main/booking/lesride_location_provider.dart';
import 'package:lesgo/presentation/widgets/booking/lesride/lesride_booking_summary_dialog.dart';
import 'package:lesgo/presentation/widgets/booking/lesride/lesride_vehicle_selector.dart';

void main() {
  group('LesRide activation', () {
    test('LesRide is available while LesTransport remains coming soon', () {
      expect(ServiceType.lesride.isComingSoon, isFalse);
      expect(ServiceType.lesport.isComingSoon, isTrue);
    });

    test('only Tricycle is currently available', () {
      expect(LesrideVehicleOption.tricycle.isAvailable, isTrue);
      expect(LesrideVehicleOption.sedan.isAvailable, isFalse);
      expect(LesrideVehicleOption.sevenSeater.isAvailable, isFalse);
      expect(LesrideVehicleOption.sevenSeater.code, 'seven_seater');
    });

    test('order request serializes the selected vehicle at the top level', () {
      final request = CreateOrderRequestDto(
        serviceId: 2,
        estimatedDistanceM: 4000,
        pickup: OrderAddressDto(address: 'Pickup', lat: 8.4, lng: 124.6),
        dropoff: OrderAddressDto(address: 'Dropoff', lat: 8.5, lng: 124.7),
        vehicleType: LesrideVehicleOption.tricycle.code,
        passengerName: 'Test Passenger',
      );

      expect(request.toJson()['vehicle_type'], 'tricycle');
      expect(request.toJson()['passenger_name'], 'Test Passenger');
    });

    test('changing a location clears stale route distance and duration', () {
      final previousRoute = LesrideLocationState(
        distanceInKm: 8.5,
        durationInSeconds: 1200,
      );

      final cleared = previousRoute.copyWith(clearRouteMetrics: true);

      expect(cleared.distanceInKm, isNull);
      expect(cleared.durationInSeconds, isNull);
    });

    test('online payment is labeled correctly in the booking summary', () {
      expect(
        LesrideBookingSummaryDialog.formatPaymentMethod('xendit'),
        'Online Payment',
      );
    });
  });

  testWidgets('locked vehicle cards cannot be selected', (tester) async {
    final selected = <LesrideVehicleOption>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            child: LesrideVehicleSelector(
              selectedVehicle: LesrideVehicleOption.tricycle,
              onSelected: selected.add,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('lesride_vehicle_sedan')));
    await tester.tap(
      find.byKey(const ValueKey('lesride_vehicle_seven_seater')),
    );
    await tester.pump();

    expect(selected, isEmpty);
    expect(find.text('Coming Soon'), findsNWidgets(2));
  });
}
