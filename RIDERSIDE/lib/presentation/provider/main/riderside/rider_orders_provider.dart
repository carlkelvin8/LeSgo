import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/services/rider_active_order_cache.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/booking_workflow.dart';
import '../../../../domain/models/rider_order.dart';
import '../../auth/rider_auth_provider.dart';
import 'rider_duty_provider.dart';
import 'rider_history_provider.dart';
import 'rider_orders_state.dart';
import 'rider_wallet_provider.dart';

export '../../../../domain/models/rider_order.dart';
export 'rider_orders_state.dart';

class RiderOrdersNotifier extends StateNotifier<RiderOrdersState> {
  RiderOrdersNotifier(this._ref) : super(RiderOrdersState()) {
    _ref.read(riderDutyProvider.notifier).onDutyChanged = _onDutyChanged;
  }

  final Ref _ref;
  Timer? _autoRefreshTimer;
  Set<int> _knownAvailableOrderIds = {};
  String? _lastActiveStatus;
  bool _isDisposed = false;

  void _onDutyChanged() {
    if (_isDisposed) return;
    if (_ref.read(riderDutyProvider)) {
      resumeAutoRefresh();
      loadOrders(silent: true);
    } else {
      stopAutoRefresh();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _scheduleNextRefresh();
  }

  void _scheduleNextRefresh() {
    if (_isDisposed) return;
    
    final hasActiveOrder = state.activeOrder != null;
    final pushEnabled = FcmService.instance.isReady;
    final interval = pushEnabled
        ? (hasActiveOrder
            ? const Duration(seconds: 20)
            : const Duration(seconds: 60))
        : (hasActiveOrder
            ? const Duration(seconds: 10)
            : const Duration(seconds: 30));

    _autoRefreshTimer = Timer(interval, () {
      if (_isDisposed || !_ref.read(riderDutyProvider)) return;
      loadOrders(silent: true);
      _scheduleNextRefresh();
    });
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  void resumeAutoRefresh() {
    if (_isDisposed) return;
    _autoRefreshTimer?.cancel();
    _startAutoRefresh();
  }

  void reset() {
    if (_isDisposed) return;
    stopAutoRefresh();
    _knownAvailableOrderIds = {};
    _lastActiveStatus = null;
    state = RiderOrdersState();
  }

  Future<void> loadOrders({bool silent = false}) async {
    if (!_ref.read(riderDutyProvider) && silent) return;

    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isRefreshing: true, clearError: true);
    }

    try {
      final allRaw = await ApiService.getOrders(perPage: 100);
      final all = allRaw
          .map((j) => RiderOrder.fromJson(j as Map<String, dynamic>))
          .toList();

      final available = all
          .where((o) =>
              (o.status == 'pending' ||
                  o.status == 'searching_driver' ||
                  o.status == 'ready_for_pickup') &&
              o.driverId == null)
          .toList();

      final driverProfileId =
          _ref.read(riderAuthProvider).user?.driverProfileId;
      final active =
          all.where((o) => isActiveOrderForDriver(o, driverProfileId)).toList();

      final currentActive = state.activeOrder;
      if (currentActive != null &&
          isActiveOrderForDriver(currentActive, driverProfileId) &&
          !active.any((o) => o.id == currentActive.id)) {
        active.insert(0, currentActive);
      }

      active.sort((a, b) => b.id.compareTo(a.id));

      _notifyOrderChanges(available, active.isNotEmpty ? active.first : null);

      state = state.copyWith(
        availableOrders: available,
        activeOrders: active,
        activeOrder: active.isNotEmpty ? active.first : null,
        isLoading: false,
        isRefreshing: false,
        clearActiveOrder: active.isEmpty,
      );

      if (active.isNotEmpty) {
        Map<String, dynamic>? activeRaw;
        for (final raw in allRaw) {
          if (raw is Map<String, dynamic> &&
              (raw['id'] as num?)?.toInt() == active.first.id) {
            activeRaw = raw;
            break;
          }
        }
        if (activeRaw != null) {
          await RiderActiveOrderCache.saveRaw(activeRaw);
        }
      } else {
        await RiderActiveOrderCache.clear();
      }

      if (_ref.read(riderDutyProvider) &&
          (_autoRefreshTimer == null || !_autoRefreshTimer!.isActive)) {
        _startAutoRefresh();
      }
    } catch (e) {
      AppLogger.error('Error loading orders', e);
      final cached = await RiderActiveOrderCache.loadOrder();
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        activeOrder: state.activeOrder ?? cached,
        error: cached != null
            ? '${ApiService.extractError(e)} (showing cached active order)'
            : ApiService.extractError(e),
      );
    }
  }

  Future<bool> acceptOrder(int orderId) async {
    await _ref.read(riderWalletProvider.notifier).loadWallet();
    final wallet = _ref.read(riderWalletProvider);
    if (!wallet.canAcceptBooking) {
      state = state.copyWith(
        action: RiderOrderAction.none,
        actionOrderId: null,
        error: wallet.acceptBlockedMessage,
      );
      return false;
    }

    state = state.copyWith(
      action: RiderOrderAction.accepting,
      actionOrderId: orderId,
      clearError: true,
    );

    try {
      final data = await ApiService.updateOrderStatus(orderId, 'accepted');
      final updated = _parseOrder(data);
      if (updated != null) {
        final newAvailable =
            state.availableOrders.where((o) => o.id != orderId).toList();

        ApiService.trackAnalyticsEvent('rider_order_accepted', properties: {
          'order_id': orderId,
        });

        state = state.copyWith(
          availableOrders: newAvailable,
          activeOrder: updated,
          action: RiderOrderAction.none,
          actionOrderId: null,
          successMessage: 'Order #$orderId accepted!',
        );

        await loadOrders(silent: true);
        await _ref.read(riderWalletProvider.notifier).loadWallet();
        await _ref.read(riderHistoryProvider.notifier).loadHistory(silent: true);
        return true;
      }

      state = state.copyWith(
        action: RiderOrderAction.none,
        actionOrderId: null,
        error: 'Failed to accept order - invalid response',
      );
      return false;
    } catch (e) {
      AppLogger.error('Error accepting order', e);
      state = state.copyWith(
        action: RiderOrderAction.none,
        actionOrderId: null,
        error: ApiService.extractError(e),
      );
      return false;
    }
  }

  Future<bool> markPickedUp(int orderId) async {
    return _updateStatus(orderId, 'picked_up', 'Marked as picked up!');
  }

  Future<bool> markDriverArrived(int orderId) async {
    return _updateStatus(
      orderId,
      'driver_arrived_at_pickup',
      'Driver has arrived at pickup!',
    );
  }

  Future<bool> markInProgress(int orderId) async {
    return _updateStatus(orderId, 'in_progress', 'Order is now in progress!');
  }

  Future<bool> markCompleted(int orderId) async {
    final ok = await _updateStatus(orderId, 'completed', 'Order delivered!');
    if (ok) {
      await RiderActiveOrderCache.clear();
      state = state.copyWith(clearActiveOrder: true);
      ApiService.trackAnalyticsEvent('rider_order_completed', properties: {
        'order_id': orderId,
      });
    }
    return ok;
  }

  Future<bool> cancelOrder(int orderId, String reason) async {
    state = state.copyWith(
      action: RiderOrderAction.updatingStatus,
      actionOrderId: orderId,
      clearError: true,
    );

    try {
      final data = await ApiService.updateOrderStatus(
        orderId,
        'cancelled',
        cancelReason: reason,
      );
      final updated = _parseOrder(data);

      state = state.copyWith(
        activeOrder: updated,
        action: RiderOrderAction.none,
        actionOrderId: null,
        successMessage: 'Order #$orderId cancelled.',
        clearActiveOrder: true,
      );

      await loadOrders(silent: true);
      await _ref.read(riderHistoryProvider.notifier).loadHistory(silent: true);
      return true;
    } catch (e) {
      AppLogger.error('Error cancelling order', e);
      state = state.copyWith(
        action: RiderOrderAction.none,
        actionOrderId: null,
        error: ApiService.extractError(e),
      );
      return false;
    }
  }

  Future<bool> _updateStatus(int orderId, String status, String msg) async {
    state = state.copyWith(
      action: RiderOrderAction.updatingStatus,
      actionOrderId: orderId,
      clearError: true,
    );
    try {
      final data = await ApiService.updateOrderStatus(orderId, status);
      final updated = _parseOrder(data);
      if (updated != null) {
        state = state.copyWith(
          activeOrder: updated,
          action: RiderOrderAction.none,
          actionOrderId: null,
          successMessage: msg,
        );
        await loadOrders(silent: true);
        await _ref.read(riderHistoryProvider.notifier).loadHistory(silent: true);
        return true;
      }
      state = state.copyWith(
        action: RiderOrderAction.none,
        actionOrderId: null,
        error: 'Failed to update status',
      );
      return false;
    } catch (e) {
      AppLogger.error('Error updating order status', e);
      state = state.copyWith(
        action: RiderOrderAction.none,
        actionOrderId: null,
        error: ApiService.extractError(e),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void _notifyOrderChanges(List<RiderOrder> available, RiderOrder? active) {
    final currentIds = available.map((o) => o.id).toSet();
    final newOrders = currentIds.difference(_knownAvailableOrderIds);
    if (_knownAvailableOrderIds.isNotEmpty && newOrders.isNotEmpty) {
      for (final id in newOrders) {
        final order = available.firstWhere((o) => o.id == id);
        PushNotificationService.show(
          title: 'New order available',
          body: '${order.serviceName} • ${order.pickupAddress}',
          payload: 'order_$id',
        );
      }
    }
    _knownAvailableOrderIds = currentIds;

    if (active != null) {
      if (_lastActiveStatus != null && _lastActiveStatus != active.status) {
        PushNotificationService.show(
          title: 'Order #${active.id} updated',
          body: 'Status changed to ${active.status.replaceAll('_', ' ')}',
          payload: 'order_${active.id}',
        );
      }
      _lastActiveStatus = active.status;
    } else {
      _lastActiveStatus = null;
    }
  }

  RiderOrder? _enrichAcceptedOrder(RiderOrder? order) {
    if (order == null) return null;
    if (order.driverId != null) return order;
    if (!BookingWorkflow.isActiveApiStatus(order.status)) return order;

    final profileId = _ref.read(riderAuthProvider).user?.driverProfileId;
    if (profileId == null) return order;
    return order.copyWith(driverId: profileId);
  }

  RiderOrder? _parseOrder(Map<String, dynamic> data) {
    try {
      final orderData = data['data'] ?? data['order'];
      if (orderData is Map<String, dynamic>) {
        // Validate required fields before parsing
        if (orderData['id'] == null || orderData['status'] == null) {
          AppLogger.warn('⚠️ Order data missing required fields: id or status');
          return null;
        }
        return _enrichAcceptedOrder(RiderOrder.fromJson(orderData));
      }
    } catch (e) {
      AppLogger.error('❌ Error parsing order data: $e');
    }
    return null;
  }
}

final riderOrdersProvider =
    StateNotifierProvider<RiderOrdersNotifier, RiderOrdersState>(
  (ref) => RiderOrdersNotifier(ref),
);
