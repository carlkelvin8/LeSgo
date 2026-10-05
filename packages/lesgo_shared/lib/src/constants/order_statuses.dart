/// String constants for order statuses used in API communication.
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

  static const List<String> activeStatuses = [
    pending,
    accepted,
    driverAssigned,
    driverArrived,
    inProgress,
    pickedUp,
  ];

  static const List<String> terminalStatuses = [
    delivered,
    completed,
    cancelled,
    failed,
  ];

  static bool isActive(String status) => activeStatuses.contains(status);
  static bool isTerminal(String status) => terminalStatuses.contains(status);
}
