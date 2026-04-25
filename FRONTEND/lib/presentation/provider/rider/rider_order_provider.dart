import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/di/local_storage_service.dart';
import '../../../data/data_source/dto/order/order_dto.dart';

enum RiderOrderAction { none, accepting, updatingStatus }

class RiderOrderState {
  final List<OrderDto> availableOrders; // pending orders (no driver yet)
  final OrderDto? activeOrder; // order currently assigned to this driver
  final bool isLoading;
  final bool isRefreshing;
  final RiderOrderAction action;
  final String? error;
  final String? successMessage;

  RiderOrderState({
    this.availableOrders = const [],
    this.activeOrder,
    this.isLoading = false,
    this.isRefreshing = false,
    this.action = RiderOrderAction.none,
    this.error,
    this.successMessage,
  });

  bool get hasActiveOrder => activeOrder != null;
  bool get isActionInProgress => action != RiderOrderAction.none;

  RiderOrderState copyWith({
    List<OrderDto>? availableOrders,
    OrderDto? activeOrder,
    bool? isLoading,
    bool? isRefreshing,
    RiderOrderAction? action,
    String? error,
    String? successMessage,
    bool clearActiveOrder = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return RiderOrderState(
      availableOrders: availableOrders ?? this.availableOrders,
      activeOrder: clearActiveOrder ? null : (activeOrder ?? this.activeOrder),
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      action: action ?? this.action,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class RiderOrderNotifier extends StateNotifier<RiderOrderState> {
  RiderOrderNotifier() : super(RiderOrderState()) {
    loadOrders();
  }

  Future<void> loadOrders({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isRefreshing: true, clearError: true);
    }

    try {
      final dio = getIt<Dio>();

      // Load pending/available orders (no driver assigned yet)
      final pendingRes = await dio.get(
        ApiConstants.orders,
        queryParameters: {'status': 'pending', 'per_page': 30},
      );

      // Load my active order (accepted or picked_up)
      final activeRes = await dio.get(
        ApiConstants.orders,
        queryParameters: {'per_page': 5},
      );

      final List<dynamic> pendingData =
          (pendingRes.data['data'] as List<dynamic>?) ?? [];
      final List<dynamic> allData =
          (activeRes.data['data'] as List<dynamic>?) ?? [];

      final available = pendingData
          .map((j) => OrderDto.fromJson(j as Map<String, dynamic>))
          .where((o) => o.driverId == null) // truly unassigned
          .toList();

      // Active = accepted or picked_up assigned to me
      final active = allData
          .map((j) => OrderDto.fromJson(j as Map<String, dynamic>))
          .where((o) =>
              o.status == 'accepted' || o.status == 'picked_up')
          .toList();

      state = state.copyWith(
        availableOrders: available,
        activeOrder: active.isNotEmpty ? active.first : null,
        isLoading: false,
        isRefreshing: false,
        clearActiveOrder: active.isEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: _extractError(e),
      );
    }
  }

  Future<bool> acceptOrder(int orderId) async {
    state = state.copyWith(action: RiderOrderAction.accepting, clearError: true);
    try {
      final dio = getIt<Dio>();
      final res = await dio.patch(
        ApiConstants.orderStatus(orderId),
        data: {'status': 'accepted'},
      );

      final updated = _parseOrderFromResponse(res.data);
      if (updated != null) {
        // Remove from available, set as active
        state = state.copyWith(
          availableOrders: state.availableOrders
              .where((o) => o.id != orderId)
              .toList(),
          activeOrder: updated,
          action: RiderOrderAction.none,
          successMessage: 'Order #$orderId accepted!',
        );
        return true;
      }
      state = state.copyWith(
        action: RiderOrderAction.none,
        error: 'Failed to accept order',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        action: RiderOrderAction.none,
        error: _extractError(e),
      );
      return false;
    }
  }

  Future<bool> markPickedUp(int orderId) async {
    return _updateStatus(orderId, 'picked_up', 'Order marked as picked up!');
  }

  Future<bool> markCompleted(int orderId) async {
    final success =
        await _updateStatus(orderId, 'completed', 'Order completed!');
    if (success) {
      state = state.copyWith(clearActiveOrder: true);
      // Refresh available orders
      await loadOrders(silent: true);
    }
    return success;
  }

  Future<bool> _updateStatus(
      int orderId, String status, String successMsg) async {
    state = state.copyWith(
        action: RiderOrderAction.updatingStatus, clearError: true);
    try {
      final dio = getIt<Dio>();
      final res = await dio.patch(
        ApiConstants.orderStatus(orderId),
        data: {'status': status},
      );

      final updated = _parseOrderFromResponse(res.data);
      if (updated != null) {
        state = state.copyWith(
          activeOrder: updated,
          action: RiderOrderAction.none,
          successMessage: successMsg,
        );
        return true;
      }
      state = state.copyWith(
        action: RiderOrderAction.none,
        error: 'Failed to update status',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        action: RiderOrderAction.none,
        error: _extractError(e),
      );
      return false;
    }
  }

  Future<void> updateLocation(double lat, double lng) async {
    try {
      final localStorage = getIt<LocalStorageService>();
      final token = localStorage.token;
      if (token == null) return;

      final dio = getIt<Dio>();
      // We need the driver profile ID — for now use the active order's driver_id
      final driverId = state.activeOrder?.driverId;
      if (driverId == null) return;

      await dio.patch(
        '/v1/drivers/$driverId/location',
        data: {'last_latitude': lat, 'last_longitude': lng},
      );
    } catch (_) {
      // Silent fail — location update is best-effort
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  OrderDto? _parseOrderFromResponse(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        final orderData = data['data'] ?? data['order'];
        if (orderData is Map<String, dynamic>) {
          return OrderDto.fromJson(orderData);
        }
      }
    } catch (_) {}
    return null;
  }

  String _extractError(dynamic e) {
    if (e is DioException) {
      final msg = e.response?.data?['message'];
      if (msg is String) return msg;
      return e.message ?? 'Network error';
    }
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }
}

final riderOrderProvider =
    StateNotifierProvider<RiderOrderNotifier, RiderOrderState>(
        (ref) => RiderOrderNotifier());
