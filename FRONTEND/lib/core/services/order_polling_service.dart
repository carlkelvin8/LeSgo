import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../constants/polling_intervals.dart';
import '../utils/order_status_utils.dart';
import '../../data/data_source/dto/order/order_dto.dart';
import '../../data/data_source/order_remote_datasource.dart';

enum OrderPollTier {
  waiting,
  status,
}

class OrderPollUpdate {
  final int orderId;
  final String status;
  final OrderDto order;

  const OrderPollUpdate({
    required this.orderId,
    required this.status,
    required this.order,
  });
}

typedef OrderPollListener = void Function(OrderPollUpdate update);

/// Single shared poller per order — avoids duplicate 5s timers across screens.
@lazySingleton
class OrderPollingService {
  final OrderRemoteDataSource _orderRemoteDataSource;
  final Map<int, _OrderPollEntry> _entries = {};

  OrderPollingService(this._orderRemoteDataSource);

  /// Returns a cancel function. Call it in [State.dispose].
  VoidCallback watchOrder(
    int orderId, {
    OrderPollTier tier = OrderPollTier.status,
    required OrderPollListener listener,
  }) {
    final entry = _entries.putIfAbsent(
      orderId,
      () => _OrderPollEntry(orderId, _orderRemoteDataSource),
    );

    entry.refCount++;
    entry.applyTier(tier);
    entry.listeners.add(listener);
    entry.ensureRunning();

    return () => _release(orderId, listener);
  }

  void _release(int orderId, OrderPollListener listener) {
    final entry = _entries[orderId];
    if (entry == null) return;

    entry.listeners.remove(listener);
    entry.refCount = (entry.refCount - 1).clamp(0, 999);
    if (entry.refCount <= 0 && entry.listeners.isEmpty) {
      entry.dispose();
      _entries.remove(orderId);
    }
  }
}

class _OrderPollEntry {
  _OrderPollEntry(this.orderId, this._orderRemoteDataSource);

  final int orderId;
  final OrderRemoteDataSource _orderRemoteDataSource;
  final Set<OrderPollListener> listeners = {};
  Timer? _timer;
  OrderPollTier _tier = OrderPollTier.status;
  int refCount = 0;
  bool _inFlight = false;

  void applyTier(OrderPollTier tier) {
    if (tier == OrderPollTier.waiting && _tier != OrderPollTier.waiting) {
      _tier = OrderPollTier.waiting;
      _restartTimer();
    }
  }

  Duration get _interval => _tier == OrderPollTier.waiting
      ? PollingIntervals.waiting
      : PollingIntervals.orderStatus;

  void ensureRunning() {
    _timer ??= Timer.periodic(_interval, (_) => _poll());
    unawaited(_poll());
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => _poll());
  }

  Future<void> _poll() async {
    if (_inFlight || listeners.isEmpty) return;
    _inFlight = true;

    try {
      final response = await _orderRemoteDataSource.getOrder(orderId);
      if (!response.success) return;

      final order = response.data;
      final update = OrderPollUpdate(
        orderId: orderId,
        status: order.status,
        order: order,
      );

      for (final listener in List<OrderPollListener>.from(listeners)) {
        listener(update);
      }

      if (OrderStatusUtils.isTerminal(order.status)) {
        _timer?.cancel();
        _timer = null;
      }
    } catch (e) {
      debugPrint('OrderPollingService poll failed for $orderId: $e');
    } finally {
      _inFlight = false;
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    listeners.clear();
  }
}
