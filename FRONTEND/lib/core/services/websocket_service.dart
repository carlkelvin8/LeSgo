import 'dart:async';

import 'package:flutter/foundation.dart';

import '../di/injection.dart';
import '../../data/data_source/order_remote_datasource.dart';
import '../../data/data_source/tracking_remote_datasource.dart';
import 'order_snapshot_cache.dart';

/// Polls tracking APIs and emits order events when a live WebSocket backend is unavailable.
class WebSocketService {
  final Map<int, StreamController<Map<String, dynamic>>> _controllers = {};
  final Map<int, Timer> _pollTimers = {};
  final Map<int, String> _lastStatusByOrder = {};

  Future<void> initialize() async {
    await OrderSnapshotCache.loadFromDisk();
  }

  void connect() {}

  void disconnect() {
    for (final id in _pollTimers.keys.toList()) {
      unsubscribeFromOrder(id);
    }
  }

  void send(String message) {
    debugPrint('WebSocketService.send (noop): $message');
  }

  Future<void> subscribeToOrder(int orderId, String token) async {
    if (_controllers.containsKey(orderId)) return;

    _controllers[orderId] =
        StreamController<Map<String, dynamic>>.broadcast();

    _pollTimers[orderId] = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollOrder(orderId);
    });

    await _pollOrder(orderId);
  }

  void unsubscribeFromOrder(int orderId) {
    _pollTimers.remove(orderId)?.cancel();
    _controllers.remove(orderId)?.close();
    _lastStatusByOrder.remove(orderId);
  }

  Stream<Map<String, dynamic>> getOrderEventStream(int orderId) {
    return _controllers[orderId]?.stream ?? const Stream.empty();
  }

  Future<void> _pollOrder(int orderId) async {
    final controller = _controllers[orderId];
    if (controller == null || controller.isClosed) return;

    try {
      final trackingDs = getIt<TrackingRemoteDataSource>();
      final orderDs = getIt<OrderRemoteDataSource>();

      final locationResponse = await trackingDs.getDriverLocation(orderId);
      if (locationResponse.success) {
        final loc = locationResponse.data;
        final lat = loc.currentLat;
        final lng = loc.currentLng;
        if (lat != null && lng != null) {
          controller.add({
            'event': 'driver.location.updated',
            'data': {
              'location': {'latitude': lat, 'longitude': lng},
            },
          });
        }
      }

      final orderResponse = await orderDs.getOrder(orderId);
      if (orderResponse.success) {
        final status = orderResponse.data.status;
        if (_lastStatusByOrder[orderId] != status) {
          _lastStatusByOrder[orderId] = status;
          controller.add({
            'event': 'order.status.updated',
            'data': {'new_status': status},
          });
        }
      }
    } catch (e) {
      debugPrint('WebSocketService poll error for order $orderId: $e');
    }
  }
}
