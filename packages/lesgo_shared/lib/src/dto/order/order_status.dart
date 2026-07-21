/// Canonical order status values shared across Customer and Rider apps.
enum OrderStatus {
  pending,
  accepted,
  driverAssigned,
  driverArrived,
  inProgress,
  pickedUp,
  delivered,
  completed,
  cancelled,
  failed;

  /// Parse from API string value.
  static OrderStatus fromString(String value) {
    switch (value.toLowerCase().replaceAll('_', '').replaceAll('-', '')) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'driverassigned':
        return OrderStatus.driverAssigned;
      case 'driverarrived':
        return OrderStatus.driverArrived;
      case 'inprogress':
        return OrderStatus.inProgress;
      case 'pickedup':
        return OrderStatus.pickedUp;
      case 'delivered':
        return OrderStatus.delivered;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'failed':
        return OrderStatus.failed;
      default:
        return OrderStatus.pending;
    }
  }

  /// Convert to API string value (snake_case).
  String toApiString() {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.driverAssigned:
        return 'driver_assigned';
      case OrderStatus.driverArrived:
        return 'driver_arrived';
      case OrderStatus.inProgress:
        return 'in_progress';
      case OrderStatus.pickedUp:
        return 'picked_up';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.failed:
        return 'failed';
    }
  }

  /// Human-readable label.
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.driverAssigned:
        return 'Driver Assigned';
      case OrderStatus.driverArrived:
        return 'Driver Arrived';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.failed:
        return 'Failed';
    }
  }
}
