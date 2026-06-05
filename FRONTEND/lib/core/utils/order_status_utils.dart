/// Helpers for stopping background polls when an order is finished.
class OrderStatusUtils {
  OrderStatusUtils._();

  static const _terminalStatuses = {
    'completed',
    'delivered',
    'cancelled',
    'failed',
  };

  static bool isTerminal(String? status) {
    if (status == null || status.isEmpty) return false;
    return _terminalStatuses.contains(status.toLowerCase());
  }

  static bool isActiveTracking(String? status) {
    if (status == null || status.isEmpty) return false;
    const active = {
      'accepted',
      'driver_arrived',
      'driver_arrived_at_pickup',
      'ready_for_pickup',
      'picked_up',
      'pickedup',
      'in_progress',
      'in_transit',
      'intransit',
      'on_the_way',
      'searching_driver',
    };
    return active.contains(status.toLowerCase());
  }
}
