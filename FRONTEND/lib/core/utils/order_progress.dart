import 'package:intl/intl.dart';

/// Turns a raw order status into what a customer wants to know: a plain
/// sentence ("Your food is being prepared") and where the order is on a
/// four-step progress bar.
class OrderProgress {
  const OrderProgress({
    required this.headline,
    required this.stepIndex,
    required this.stepLabels,
  });

  final String headline;

  /// 0-based index into [stepLabels] of the current step.
  final int stepIndex;
  final List<String> stepLabels;

  static const _rideSteps = ['Booked', 'Driver coming', 'On trip', 'Arrived'];
  static const _deliverySteps = ['Placed', 'Preparing', 'On the way', 'Delivered'];

  /// [service] is the display label from `OrderServiceLabels`
  /// ("LesRide", "LesEat", "LesBuy", "LesGo", ...).
  static OrderProgress of({
    required String service,
    required String? status,
    String? scheduledAt,
  }) {
    final s = (status ?? '').toLowerCase().trim();
    final isRide = service == 'LesRide' || service == 'LesTransport';
    final isFood = service == 'LesEat';
    final isShop = service == 'LesBuy';
    final labels = isRide ? _rideSteps : _deliverySteps;

    OrderProgress p(String headline, int step) =>
        OrderProgress(headline: headline, stepIndex: step, stepLabels: labels);

    switch (s) {
      case 'scheduled':
        final when = DateTime.tryParse(scheduledAt ?? '')?.toLocal();
        return p(
          when == null
              ? 'Scheduled'
              : 'Scheduled for ${DateFormat('MMM d, h:mm a').format(when)}',
          0,
        );
      case 'pending':
      case 'searching_driver':
        return p(
          isFood || isShop
              ? 'Waiting for the store to confirm'
              : 'Finding you a driver',
          0,
        );
      case 'accepted':
      case 'preparing':
      case 'cooking':
        if (isRide) return p('Your driver is on the way', 1);
        if (isFood) return p('Your food is being prepared', 1);
        if (isShop) return p('Your items are being prepared', 1);
        return p('Driver is heading to the pickup', 1);
      case 'driver_assigned':
      case 'ready_for_pickup':
        return p(
          isRide ? 'Your driver is on the way' : 'Driver is picking up your order',
          1,
        );
      case 'driver_arrived':
      case 'driver_arrived_at_pickup':
        return p(
          isRide ? 'Your driver has arrived' : 'Driver has arrived at the pickup',
          1,
        );
      case 'picked_up':
      case 'pickedup':
      case 'in_progress':
      case 'in_transit':
      case 'intransit':
      case 'on_the_way':
      case 'delivering':
        return p(isRide ? 'You are on your trip' : 'Your order is on the way', 2);
      case 'completed':
      case 'delivered':
        return p(isRide ? 'You have arrived' : 'Delivered', 3);
      default:
        final pretty = s.isEmpty
            ? 'In progress'
            : s
                  .replaceAll('_', ' ')
                  .replaceFirstMapped(RegExp(r'^.'), (m) => m[0]!.toUpperCase());
        return p(pretty, 0);
    }
  }
}
