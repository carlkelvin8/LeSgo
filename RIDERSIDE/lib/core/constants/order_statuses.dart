/// Order status string constants for the Rider app.
/// Identical to Customer app — will be replaced by lesgo_shared import later.
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

  static const List<String> active = [
    pending, accepted, driverAssigned, driverArrived, inProgress, pickedUp,
  ];

  static const List<String> terminal = [
    delivered, completed, cancelled, failed,
  ];

  static bool isActive(String? status) =>
      status != null && active.contains(status);

  static bool isTerminal(String? status) =>
      status != null && terminal.contains(status);

  static String label(String? status) {
    switch (status) {
      case pending: return 'Pending';
      case accepted: return 'Accepted';
      case driverAssigned: return 'Driver Assigned';
      case driverArrived: return 'Driver Arrived';
      case inProgress: return 'In Progress';
      case pickedUp: return 'Picked Up';
      case delivered: return 'Delivered';
      case completed: return 'Completed';
      case cancelled: return 'Cancelled';
      case failed: return 'Failed';
      default: return status ?? 'Unknown';
    }
  }
}
