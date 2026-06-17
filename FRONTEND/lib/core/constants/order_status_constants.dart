/// Centralized order status constants to avoid hardcoding status strings throughout the codebase.
/// Using constants ensures consistency and makes it easier to refactor status values.
class OrderStatusConstants {
  // Order Statuses
  static const String pending = 'pending';
  static const String scheduled = 'scheduled';
  static const String accepted = 'accepted';
  static const String driverArrivedAtPickup = 'driver_arrived_at_pickup';
  static const String inProgress = 'in_progress';
  static const String pickedUp = 'picked_up';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String failed = 'failed';

  // Payment Status Constants
  static const String paid = 'paid';
  static const String pending_payment = 'pending';
  static const String refunded = 'refunded';
  static const String unpaid = 'unpaid';

  // Payment Method Constants
  static const String cash = 'cash';
  static const String wallet = 'wallet';
  static const String card = 'card';
  static const String mobileMoney = 'mobile_money';

  /// Get all active statuses (not completed or cancelled)
  static const List<String> activeStatuses = [
    pending,
    scheduled,
    accepted,
    driverArrivedAtPickup,
    inProgress,
    pickedUp,
  ];

  /// Get all terminal statuses (order is finished)
  static const List<String> terminalStatuses = [
    completed,
    cancelled,
    failed,
  ];

  /// Check if status is active (order not finished)
  static bool isActive(String status) => activeStatuses.contains(status.toLowerCase());

  /// Check if status is terminal (order finished)
  static bool isTerminal(String status) => terminalStatuses.contains(status.toLowerCase());

  /// Get display name for status
  static String displayName(String status) {
    switch (status.toLowerCase()) {
      case pending:
        return 'Pending';
      case scheduled:
        return 'Scheduled';
      case accepted:
        return 'Accepted';
      case driverArrivedAtPickup:
        return 'Driver Arrived';
      case inProgress:
        return 'In Progress';
      case pickedUp:
        return 'Picked Up';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      case failed:
        return 'Failed';
      default:
        return status;
    }
  }
}
