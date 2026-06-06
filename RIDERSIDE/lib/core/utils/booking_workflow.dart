import '../../domain/entities/rider_booking.dart';

/// Driver-facing order workflow helpers for progressive status UX.
class BookingWorkflow {
  BookingWorkflow._();

  static BookingCategory categoryFromServiceId(int serviceId) {
    switch (serviceId) {
      case 3:
        return BookingCategory.lesEat;
      case 4:
        return BookingCategory.lesBuy;
      case 2:
        return BookingCategory.lesRide;
      default:
        return BookingCategory.lesRide;
    }
  }

  static BookingStatus mapApiStatus(String apiStatus, int serviceId) {
    final status = apiStatus.toLowerCase();
    if (status == 'cancelled') return BookingStatus.cancelled;
    if (status == 'searching_driver') return BookingStatus.pending;

    final category = categoryFromServiceId(serviceId);

    if (category == BookingCategory.lesRide) {
      switch (status) {
        case 'accepted':
          return BookingStatus.onTheWay;
        case 'driver_arrived_at_pickup':
          return BookingStatus.driverHasArrived;
        case 'in_progress':
          return BookingStatus.inProgress;
        case 'picked_up':
          return BookingStatus.onTheWayGoing;
        case 'completed':
          return BookingStatus.complete;
        default:
          return BookingStatus.onTheWay;
      }
    }

    if (category == BookingCategory.lesEat) {
      switch (status) {
        case 'pending':
          return BookingStatus.pending;
        case 'accepted':
        case 'driver_arrived_at_pickup':
        case 'in_progress':
          return BookingStatus.cooking;
        case 'ready_for_pickup':
          return BookingStatus.forPickUp;
        case 'picked_up':
          return BookingStatus.forDelivery;
        case 'completed':
          return BookingStatus.delivered;
        default:
          return BookingStatus.cooking;
      }
    }

    if (category == BookingCategory.lesBuy) {
      switch (status) {
        case 'pending':
          return BookingStatus.pending;
        case 'accepted':
        case 'driver_arrived_at_pickup':
        case 'in_progress':
          return BookingStatus.toBuy;
        case 'ready_for_pickup':
          return BookingStatus.forPickUp;
        case 'picked_up':
          return BookingStatus.forDelivery;
        case 'completed':
          return BookingStatus.delivered;
        default:
          return BookingStatus.toBuy;
      }
    }

    return BookingStatus.pending;
  }

  static int workflowStepIndex(String apiStatus) {
    switch (apiStatus.toLowerCase()) {
      case 'accepted':
        return 0;
      case 'ready_for_pickup':
        return 1;
      case 'driver_arrived_at_pickup':
      case 'in_progress':
        return 1;
      case 'picked_up':
        return 2;
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  static const stepLabels = [
    'Accepted',
    'At pickup',
    'En route',
    'Done',
  ];

  static bool isTerminal(String? apiStatus) {
    final s = apiStatus?.toLowerCase();
    return s == 'completed' || s == 'cancelled';
  }

  static const Set<String> activeApiStatuses = {
    'accepted',
    'ready_for_pickup',
    'driver_arrived_at_pickup',
    'in_progress',
    'picked_up',
  };

  static bool isActiveApiStatus(String? apiStatus) {
    return activeApiStatuses.contains(apiStatus?.toLowerCase());
  }

  static int? extractDriverId(Map<String, dynamic> order) {
    final direct = order['driver_id'];
    if (direct is num) return direct.toInt();
    if (direct is String) return int.tryParse(direct);

    final driverProfile = order['driver_profile'];
    if (driverProfile is Map) {
      final id = driverProfile['id'];
      if (id is num) return id.toInt();
      if (id is String) return int.tryParse(id);
    }
    return null;
  }

  /// Orders shown in rider history: completed/cancelled + in-progress assigned jobs.
  static bool isHistoryEligible(Map<String, dynamic> order) {
    final status = (order['status'] as String?)?.toLowerCase();
    if (status == null) return false;
    if (isTerminal(status)) return true;

    final driverId = extractDriverId(order);
    if (status == 'picked_up' || isActiveApiStatus(status)) {
      return driverId != null;
    }
    return false;
  }

  static bool isProcessingBookingStatus(BookingStatus status) {
    return status != BookingStatus.complete &&
        status != BookingStatus.delivered &&
        status != BookingStatus.cancelled;
  }

  static List<BookingNextAction> nextActions({
    required String? apiStatus,
    required BookingCategory category,
    bool awaitingProof = false,
  }) {
    if (apiStatus == null || isTerminal(apiStatus)) return [];

    switch (apiStatus.toLowerCase()) {
      case 'accepted':
        return [
          BookingNextAction(
            targetStatus: BookingStatus.driverHasArrived,
            title: category == BookingCategory.lesRide
                ? 'Arrived at pickup'
                : 'Arrived at restaurant',
            subtitle: 'Tap when you reach the pickup location',
            iconName: 'location_on',
          ),
        ];
      case 'ready_for_pickup':
        return [
          BookingNextAction(
            targetStatus: BookingStatus.driverHasArrived,
            title: category == BookingCategory.lesRide
                ? 'Arrived at pickup'
                : 'Arrived at restaurant',
            subtitle: 'Order is ready — go pick it up',
            iconName: 'location_on',
          ),
          BookingNextAction(
            targetStatus: _pickedUpStatus(category),
            title: category == BookingCategory.lesRide
                ? 'Passenger picked up'
                : 'Order picked up',
            subtitle: 'Confirm you collected the order',
            iconName: 'check_circle',
          ),
        ];
      case 'driver_arrived_at_pickup':
      case 'in_progress':
        return [
          BookingNextAction(
            targetStatus: _pickedUpStatus(category),
            title: category == BookingCategory.lesRide
                ? 'Passenger picked up'
                : 'Order picked up',
            subtitle: category == BookingCategory.lesRide
                ? 'Start the trip to drop-off'
                : 'Confirm you collected the order',
            iconName: 'check_circle',
          ),
        ];
      case 'picked_up':
        if (awaitingProof) {
          return [
            BookingNextAction(
              targetStatus: _completeStatus(category),
              title: category == BookingCategory.lesRide
                  ? 'Complete trip'
                  : 'Complete delivery',
              subtitle: 'Confirm after uploading proof photo',
              iconName: 'camera',
            ),
          ];
        }
        return [
          BookingNextAction(
            targetStatus: _completeStatus(category),
            title: category == BookingCategory.lesRide
                ? 'Arrived at drop-off'
                : 'Arrived at customer',
            subtitle: 'Tap when you reach the drop-off location',
            iconName: 'location_on',
          ),
        ];
      default:
        return [];
    }
  }

  static BookingStatus _pickedUpStatus(BookingCategory category) {
    switch (category) {
      case BookingCategory.lesEat:
        return BookingStatus.forPickUp;
      case BookingCategory.lesBuy:
        return BookingStatus.forDelivery;
      case BookingCategory.lesRide:
        return BookingStatus.onTheWayGoing;
    }
  }

  static BookingStatus _completeStatus(BookingCategory category) {
    return category == BookingCategory.lesRide
        ? BookingStatus.complete
        : BookingStatus.delivered;
  }
}

class BookingNextAction {
  final BookingStatus targetStatus;
  final String title;
  final String subtitle;
  final String iconName;

  const BookingNextAction({
    required this.targetStatus,
    required this.title,
    required this.subtitle,
    required this.iconName,
  });
}
