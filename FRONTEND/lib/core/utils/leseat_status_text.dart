/// Customer-facing wording for LesEat order statuses (title + subtext).
///
/// Unknown statuses never show a raw enum such as READY_FOR_PICKUP.
class LesEatStatusText {
  LesEatStatusText._();

  static String title(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Finding Driver';
      case 'accepted':
        return 'Driver Accepted';
      case 'driver_arrived_at_pickup':
        return 'Rider at Restaurant';
      case 'in_progress':
        return 'Preparing Your Order';
      case 'ready_for_pickup':
        return 'Order Ready';
      case 'picked_up':
        return 'Order Picked Up';
      case 'in_transit':
        return 'On The Way';
      case 'completed':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'failed':
        return 'Failed';
      default:
        // Never show a raw enum such as READY_FOR_PICKUP to the customer.
        final words = status.replaceAll('_', ' ').trim();
        return words.isEmpty
            ? 'Order Update'
            : words[0].toUpperCase() + words.substring(1);
    }
  }

  static String subtext(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Looking for a nearby rider';
      case 'accepted':
        return 'Your rider is on the way to the restaurant';
      case 'driver_arrived_at_pickup':
        return 'Rider arrived at the restaurant';
      case 'in_progress':
        return 'Your food is being prepared';
      case 'ready_for_pickup':
        return 'Your food is ready and waiting for the rider';
      case 'picked_up':
        return 'Your order is on its way to you';
      case 'in_transit':
        return 'Your rider is heading to your location';
      case 'completed':
        return 'Your order has been delivered';
      case 'cancelled':
        return 'This order was cancelled';
      case 'failed':
        return 'Something went wrong with this order';
      case 'scheduled':
        return 'Your order is scheduled and will be prepared at the chosen time';
      default:
        return 'We will keep you updated on your order';
    }
  }
}
