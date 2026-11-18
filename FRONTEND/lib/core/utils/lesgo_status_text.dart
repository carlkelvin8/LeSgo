/// Customer-facing text for the real server order statuses of a LesGo
/// delivery (pending/searching_driver, accepted, driver_arrived_at_pickup,
/// in_progress, picked_up, completed, cancelled, failed).
class LesgoStatusText {
  LesgoStatusText._();

  static String _norm(String? status) => (status ?? '').trim().toLowerCase();

  static String title(String? status) {
    switch (_norm(status)) {
      case 'pending':
      case 'searching_driver':
        return 'Finding Driver';
      case 'accepted':
      case 'assigned':
        return 'Driver Accepted';
      case 'driver_arrived_at_pickup':
      case 'driver_arrived':
        return 'Driver Arrived';
      case 'picked_up':
        return 'Package Picked Up';
      case 'in_progress':
      case 'in_transit':
        return 'On The Way';
      case 'completed':
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'failed':
        return 'Failed';
      default:
        return _humanize(status);
    }
  }

  static String description(String? status) {
    switch (_norm(status)) {
      case 'pending':
      case 'searching_driver':
        return 'Looking for available driver';
      case 'accepted':
      case 'assigned':
        return 'Driver is on the way to pickup location';
      case 'driver_arrived_at_pickup':
      case 'driver_arrived':
        return 'Driver has arrived at pickup location';
      case 'picked_up':
        return 'Package has been picked up';
      case 'in_progress':
      case 'in_transit':
        return 'Package is being delivered';
      case 'completed':
      case 'delivered':
        return 'Package has been delivered successfully';
      case 'cancelled':
        return 'Order has been cancelled';
      case 'failed':
        return 'Delivery failed';
      default:
        return 'Order update: ${_humanize(status)}';
    }
  }

  /// "some_new_status" -> "Some New Status" (never shows raw snake_case).
  static String _humanize(String? status) {
    final words = _norm(status)
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}');
    final text = words.join(' ');
    return text.isEmpty ? 'Updating' : text;
  }
}
