/// Maps backend order status strings to LesEat order status UI keys.
class OrderStatusMapper {
  OrderStatusMapper._();

  /// UI keys used by [LeseatOrderStatusScreen]: cooking, ready_for_pickup,
  /// on_the_way, completed.
  static String toLesEatUiStatus(String? apiStatus) {
    final s = (apiStatus ?? '').toLowerCase().trim();
    switch (s) {
      case 'pending':
      case 'searching_driver':
      case 'accepted':
      case 'preparing':
      case 'cooking':
        return 'cooking';
      case 'ready_for_pickup':
      case 'driver_assigned':
      case 'picked_up':
        return 'ready_for_pickup';
      case 'on_the_way':
      case 'delivering':
      case 'in_transit':
        return 'on_the_way';
      case 'completed':
      case 'delivered':
        return 'completed';
      case 'cancelled':
      case 'failed':
        return 'cancelled';
      default:
        return 'cooking';
    }
  }

  static bool isTerminal(String? apiStatus) {
    final s = (apiStatus ?? '').toLowerCase();
    return s == 'completed' ||
        s == 'delivered' ||
        s == 'cancelled' ||
        s == 'failed';
  }
}
