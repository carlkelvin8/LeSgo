import '../../../../core/utils/booking_workflow.dart';
import '../../../../domain/models/rider_order.dart';

bool isActiveOrderForDriver(RiderOrder order, int? driverProfileId) {
  if (!BookingWorkflow.isActiveApiStatus(order.status)) return false;
  if (order.driverId == null) return false;
  if (driverProfileId == null) return false;
  return order.driverId == driverProfileId;
}

/// Preserve a locally accepted order only when absent from a paginated response.
/// A returned terminal status or reassignment always supersedes the local copy.
List<RiderOrder> reconcileActiveOrders(
  List<RiderOrder> fetched,
  RiderOrder? current,
  int? driverProfileId,
) {
  final active = fetched
      .where((order) => isActiveOrderForDriver(order, driverProfileId))
      .toList();
  if (current != null &&
      isActiveOrderForDriver(current, driverProfileId) &&
      !fetched.any((order) => order.id == current.id)) {
    active.add(current);
  }
  active.sort((a, b) => b.id.compareTo(a.id));
  return active;
}

enum RiderOrderAction { none, accepting, updatingStatus }

class RiderOrdersState {
  final List<RiderOrder> availableOrders;
  final List<RiderOrder> activeOrders;
  final RiderOrder? activeOrder;
  final bool isLoading;
  final bool isRefreshing;
  final RiderOrderAction action;
  final int? actionOrderId;
  final String? error;
  final String? successMessage;
  final DateTime? lastRefreshed;

  RiderOrdersState({
    this.availableOrders = const [],
    this.activeOrders = const [],
    this.activeOrder,
    this.isLoading = false,
    this.isRefreshing = false,
    this.action = RiderOrderAction.none,
    this.actionOrderId,
    this.error,
    this.successMessage,
    this.lastRefreshed,
  });

  bool get hasActiveOrder => activeOrder != null;

  RiderOrdersState copyWith({
    List<RiderOrder>? availableOrders,
    List<RiderOrder>? activeOrders,
    RiderOrder? activeOrder,
    bool? isLoading,
    bool? isRefreshing,
    RiderOrderAction? action,
    int? actionOrderId,
    String? error,
    String? successMessage,
    bool clearActiveOrder = false,
    bool clearError = false,
    bool clearSuccess = false,
    DateTime? lastRefreshed,
  }) {
    return RiderOrdersState(
      availableOrders: availableOrders ?? this.availableOrders,
      activeOrders: clearActiveOrder
          ? const []
          : (activeOrders ?? this.activeOrders),
      activeOrder: clearActiveOrder ? null : (activeOrder ?? this.activeOrder),
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      action: action ?? this.action,
      actionOrderId: action == RiderOrderAction.none
          ? null
          : (actionOrderId ?? this.actionOrderId),
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
    );
  }
}
