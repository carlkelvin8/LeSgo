import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/core/services/websocket_service.dart';
import 'package:lesgo/data/data_source/tracking_remote_datasource.dart';
import 'package:lesgo/presentation/provider/tracking/live_tracking_provider.dart';

/// The API nests the coordinates and has no driver location yet.
class _FakeTracking extends Fake implements TrackingRemoteDataSource {
  @override
  Future<Map<String, dynamic>> trackOrder(int orderId) async => {
    'success': true,
    'data': {
      'order_id': orderId,
      'status': 'in_transit',
      'pickup': {'latitude': 18.607, 'longitude': 121.0825},
      'dropoff': {'latitude': 18.612, 'longitude': 121.09},
      'driver_location': null,
    },
  };

  @override
  Future<Map<String, dynamic>> getEta(int orderId) async => {'success': false};

  @override
  Future<Map<String, dynamic>> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async => {'success': false};
}

/// Every call is a harmless no-op.
class _FakeWebSocket extends Fake implements WebSocketService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  setUp(() {
    if (getIt.isRegistered<TrackingRemoteDataSource>()) {
      getIt.unregister<TrackingRemoteDataSource>();
    }
    if (getIt.isRegistered<WebSocketService>()) {
      getIt.unregister<WebSocketService>();
    }
    getIt.registerSingleton<TrackingRemoteDataSource>(_FakeTracking());
    getIt.registerSingleton<WebSocketService>(_FakeWebSocket());
  });

  tearDown(() {
    getIt.unregister<TrackingRemoteDataSource>();
    getIt.unregister<WebSocketService>();
  });

  test('pickup and dropoff markers exist before any driver location', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(liveTrackingProvider(3), (_, __) {});
    addTearDown(sub.close);

    await Future<void>.delayed(const Duration(milliseconds: 200));

    final state = container.read(liveTrackingProvider(3));
    expect(state.driverLocation, isNull);
    expect(state.markers.map((m) => m.markerId.value).toSet(), {
      'pickup',
      'dropoff',
    });

    final bounds = container
        .read(liveTrackingProvider(3).notifier)
        .getCameraBounds();
    expect(bounds, isNotNull);
    expect(bounds!.southwest.latitude, 18.607);
    expect(bounds.northeast.latitude, 18.612);
  });
}
