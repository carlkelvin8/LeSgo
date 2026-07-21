/// Order status string constants.
/// Use these instead of raw strings to prevent typos.
///
/// Example:
/// ```dart
/// // Before (error-prone):
/// if (order.status == 'driver_assigned') { ... }
///
/// // After (safe):
/// if (order.status == OrderStatuses.driverAssigned) { ... }
/// ```
class OrderStatuses {
  OrderStatuses._();

  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String driverAssigned = 'driver_assigned';
  static const String driverArrived = 'driver_arrived';
  static const String inProgress = 'in_progress';
  static const String pickedUp = 'picked_up';
  static const String delivered = 'delivered';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String failed = 'failed';

  /// Statuses where an order is still "active" (not yet finished).
  static const List<String> active = [
    pending,
    accepted,
    driverAssigned,
    driverArrived,
    inProgress,
    pickedUp,
  ];

  /// Statuses where an order is done (terminal state).
  static const List<String> terminal = [
    delivered,
    completed,
    cancelled,
    failed,
  ];

  /// Statuses where the order can still be cancelled by the customer.
  static const List<String> cancellable = [
    pending,
    accepted,
  ];

  /// Check if a status means the order is still in progress.
  static bool isActive(String? status) =>
      status != null && active.contains(status);

  /// Check if a status means the order is finished.
  static bool isTerminal(String? status) =>
      status != null && terminal.contains(status);

  /// Check if the customer can cancel at this status.
  static bool isCancellable(String? status) =>
      status != null && cancellable.contains(status);

  /// Human-readable label for a status.
  static String label(String? status) {
    switch (status) {
      case pending:
        return 'Pending';
      case accepted:
        return 'Accepted';
      case driverAssigned:
        return 'Driver Assigned';
      case driverArrived:
        return 'Driver Arrived';
      case inProgress:
        return 'In Progress';
      case pickedUp:
        return 'Picked Up';
      case delivered:
        return 'Delivered';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      case failed:
        return 'Failed';
      default:
        return status ?? 'Unknown';
    }
  }
}
