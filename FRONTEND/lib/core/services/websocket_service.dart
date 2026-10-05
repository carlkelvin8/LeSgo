import 'dart:async';

import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../constants/polling_intervals.dart';
import '../di/injection.dart';
import '../di/local_storage_service.dart';
import '../network/dio_client.dart';
import '../utils/order_status_utils.dart';
import '../../data/data_source/order_remote_datasource.dart';
import '../../data/data_source/realtime_remote_datasource.dart';
import '../../data/data_source/tracking_remote_datasource.dart';
import 'chat_websocket_service.dart';
import 'order_snapshot_cache.dart';

/// Realtime order events via Reverb WebSocket with HTTP poll fallback.
class WebSocketService {
  final RealtimeRemoteDataSource _realtimeDs =
      getIt<RealtimeRemoteDataSource>();
  final LocalStorageService _localStorage = getIt<LocalStorageService>();
  final ChatWebSocketService _reverb = getIt<ChatWebSocketService>();
  final DioClient _dioClient = getIt<DioClient>();

  final Map<int, StreamController<Map<String, dynamic>>> _controllers = {};
  final Map<int, Timer> _pollTimers = {};
  final Map<int, String> _lastStatusByOrder = {};
  final Map<int, int> _subscriberCounts = {};
  final Map<int, String> _connectionIds = {};
  int? _userId;
  bool _reverbHandlerRegistered = false;

  late final ChatWebSocketEventHandler _reverbHandler = (eventName, payload) {
    for (final orderId in _controllers.keys.toList()) {
      _dispatchReverbEvent(orderId, eventName, payload);
    }
  };

  Future<void> initialize() async {
    await OrderSnapshotCache.loadFromDisk();
  }

  Future<void> connect() async {
    if (_localStorage.token == null || _localStorage.token!.isEmpty) {
      throw StateError('Auth token required for realtime connection');
    }
  }

  Future<void> disconnect() async {
    for (final id in _pollTimers.keys.toList()) {
      await unsubscribeFromOrder(id);
    }
    _reverb.removeHandler(_reverbHandler);
    _userId = null;
  }

  void send(String message) {
    debugPrint('WebSocketService.send: $message');
  }

  Future<void> subscribeToOrder(int orderId, String token) async {
    final authToken = token.isNotEmpty ? token : (_localStorage.token ?? '');
    if (authToken.isEmpty) {
      throw StateError('Missing auth token for order subscription');
    }

    _subscriberCounts[orderId] = (_subscriberCounts[orderId] ?? 0) + 1;
    if (_controllers.containsKey(orderId)) return;

    _controllers[orderId] =
        StreamController<Map<String, dynamic>>.broadcast();

    try {
      final connectionResponse =
          await _realtimeDs.connect(platform: 'mobile');
      final connectionId =
          connectionResponse['connection_id']?.toString() ?? '';
      if (connectionId.isNotEmpty) {
        _connectionIds[orderId] = connectionId;
      }
    } catch (e) {
      debugPrint('Realtime connect failed (tracking poll continues): $e');
    }

    await _ensureReverb(orderId);

    final pollInterval = _reverb.isConnected
        ? const Duration(seconds: 45)
        : PollingIntervals.liveTracking;

    _pollTimers[orderId] = Timer.periodic(pollInterval, (_) {
      _pollOrder(orderId);
    });

    await _pollOrder(orderId);
  }

  Future<void> _ensureReverb(int orderId) async {
    final userId = await _resolveUserId();
    if (userId == null) return;

    if (!_reverbHandlerRegistered) {
      _reverb.addHandler(_reverbHandler);
      _reverbHandlerRegistered = true;
    }
    final ok = await _reverb.connect(userId: userId);
    if (ok) {
      await _reverb.subscribeOrder(orderId);
      debugPrint('✅ Reverb subscribed to order $orderId');
    }
  }

  void _dispatchReverbEvent(
    int orderId,
    String eventName,
    Map<String, dynamic> payload,
  ) {
    final payloadOrderId = (payload['order_id'] as num?)?.toInt();
    if (payloadOrderId != null && payloadOrderId != orderId) return;

    final controller = _controllers[orderId];
    if (controller == null || controller.isClosed) return;

    if (eventName == 'driver.location.updated') {
      final location = payload['location'];
      if (location is Map) {
        controller.add({
          'event': eventName,
          'data': {'location': location},
        });
      }
      return;
    }

    if (eventName == 'order.status.updated') {
      final newStatus = payload['new_status']?.toString() ??
          payload['status']?.toString();
      if (newStatus != null) {
        controller.add({
          'event': eventName,
          'data': {'new_status': newStatus},
        });
      }
    }
  }

  Future<int?> _resolveUserId() async {
    if (_userId != null) return _userId;
    try {
      if (_localStorage.token == null) return null;
      final me = await _dioClient.dio.get(ApiConstants.authMe);
      final data = me.data['data'] as Map<String, dynamic>? ?? {};
      _userId = (data['id'] as num?)?.toInt();
      return _userId;
    } catch (_) {
      return null;
    }
  }

  Future<void> unsubscribeFromOrder(int orderId) async {
    final next = (_subscriberCounts[orderId] ?? 1) - 1;
    if (next > 0) {
      _subscriberCounts[orderId] = next;
      return;
    }

    _subscriberCounts.remove(orderId);
    _pollTimers.remove(orderId)?.cancel();

    await _reverb.unsubscribeOrder(orderId);

    final connectionId = _connectionIds.remove(orderId);
    if (connectionId != null && connectionId.isNotEmpty) {
      try {
        await _realtimeDs.disconnect(connectionId);
      } catch (_) {}
    }

    _controllers.remove(orderId)?.close();
    _lastStatusByOrder.remove(orderId);

    if (_controllers.isEmpty && _reverbHandlerRegistered) {
      _reverb.removeHandler(_reverbHandler);
      _reverbHandlerRegistered = false;
    }
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

      final connectionId = _connectionIds[orderId];
      if (connectionId != null && connectionId.isNotEmpty) {
        await _realtimeDs.ping(connectionId);
      }

      final live = await trackingDs.getLiveTracking(orderId);
      if (live != null) {
        final status = live['status']?.toString();
        final lat = live['driver_lat'];
        final lng = live['driver_lng'];
        if (lat != null && lng != null) {
          controller.add({
            'event': 'driver.location.updated',
            'data': {
              'location': {
                'latitude': (lat as num).toDouble(),
                'longitude': (lng as num).toDouble(),
              },
            },
          });
        }
        if (status != null && _lastStatusByOrder[orderId] != status) {
          _lastStatusByOrder[orderId] = status;
          controller.add({
            'event': 'order.status.updated',
            'data': {'new_status': status},
          });
        }
        if (status != null && OrderStatusUtils.isTerminal(status)) {
          await unsubscribeFromOrder(orderId);
        }
        return;
      }

      final orderResponse = await orderDs.getOrder(orderId);
      if (!orderResponse.success) return;

      final status = orderResponse.data.status;
      final shouldTrackLocation = OrderStatusUtils.isActiveTracking(status);

      if (shouldTrackLocation) {
        try {
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
        } catch (_) {}
      }

      if (_lastStatusByOrder[orderId] != status) {
        _lastStatusByOrder[orderId] = status;
        controller.add({
          'event': 'order.status.updated',
          'data': {'new_status': status},
        });
      }

      if (OrderStatusUtils.isTerminal(status)) {
        await unsubscribeFromOrder(orderId);
      }
    } catch (e) {
      debugPrint('WebSocketService poll error for order $orderId: $e');
    }
  }
}
