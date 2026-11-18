enum BookingCategory { lesEat, lesBuy, lesRide }

extension BookingCategoryX on BookingCategory {
  String get label {
    switch (this) {
      case BookingCategory.lesEat:
        return 'LesEat';
      case BookingCategory.lesBuy:
        return 'LesBuy';
      case BookingCategory.lesRide:
        return 'LesRide';
    }
  }
}

enum BookingStatus {
  // LesEat + LesBuy shared
  pending,
  // LesEat specific
  cooking,
  forPickUp,
  // LesEat + LesBuy shared
  forDelivery,
  delivered,
  // LesBuy specific
  toBuy,
  // LesRide
  onTheWay,
  onTheWayGoing,
  driverHasArrived,
  inProgress,
  complete,
  // Cancelled
  cancelled,
}

extension BookingStatusX on BookingStatus {
  /// Unified rider-facing labels for the order workflow.
  String get label {
    switch (this) {
      case BookingStatus.pending:
      case BookingStatus.onTheWay:
        return 'Order Booked';
      case BookingStatus.forPickUp:
      case BookingStatus.driverHasArrived:
        return 'For Pickup';
      case BookingStatus.cooking:
      case BookingStatus.toBuy:
      case BookingStatus.inProgress:
        return 'Order in Progress';
      case BookingStatus.forDelivery:
      case BookingStatus.onTheWayGoing:
        return 'For Delivery';
      case BookingStatus.delivered:
      case BookingStatus.complete:
        return 'Delivered';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Maps legacy/internal statuses to the unified workflow step.
  BookingStatus get workflowStep {
    switch (this) {
      case BookingStatus.pending:
      case BookingStatus.onTheWay:
        return BookingStatus.pending;
      case BookingStatus.forPickUp:
      case BookingStatus.driverHasArrived:
        return BookingStatus.forPickUp;
      case BookingStatus.cooking:
      case BookingStatus.toBuy:
      case BookingStatus.inProgress:
        return BookingStatus.inProgress;
      case BookingStatus.forDelivery:
      case BookingStatus.onTheWayGoing:
        return BookingStatus.forDelivery;
      case BookingStatus.delivered:
      case BookingStatus.complete:
        return BookingStatus.delivered;
      case BookingStatus.cancelled:
        return BookingStatus.cancelled;
    }
  }

  String? get uploadLabel {
    switch (this) {
      case BookingStatus.toBuy:
        return 'Upload picture receipt';
      case BookingStatus.forPickUp:
        return 'Upload picture';
      case BookingStatus.delivered:
        return 'Upload picture';
      case BookingStatus.complete:
        return 'Upload picture';
      case BookingStatus.cancelled:
        return null;
      default:
        return null;
    }
  }
}

extension BookingCategoryStatuses on BookingCategory {
  static const List<BookingStatus> unifiedWorkflow = [
    BookingStatus.pending,
    BookingStatus.forPickUp,
    BookingStatus.inProgress,
    BookingStatus.forDelivery,
    BookingStatus.delivered,
  ];

  List<BookingStatus> get statuses => unifiedWorkflow;
}

class RiderBooking {
  final String id;
  final int serviceId;
  final String restaurantName;
  final String customerName;
  final String address;
  final String? pickupAddress;
  final String? deliveryAddress;
  final String? distance;
  final String? estimatedTime;
  final String? earnings;
  final String? paymentMethod;
  final List<String>? items;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final String logoPath;
  final BookingCategory category;
  final String billingAmount;
  final String billingMethod;
  final String? deliveryFee;
  final String? itemsSubtotal;
  final BookingStatus currentStatus;
  final List<String>? proofOfDeliveryUrls;
  final String? customerPhone;
  final int? orderRating;

  const RiderBooking({
    required this.id,
    this.serviceId = 2,
    required this.restaurantName,
    this.customerName = 'Customer',
    required this.address,
    this.pickupAddress,
    this.deliveryAddress,
    this.distance,
    this.estimatedTime,
    this.earnings,
    this.paymentMethod,
    this.items,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.logoPath = '',
    this.category = BookingCategory.lesRide,
    this.billingAmount = 'PHP 0.00',
    this.billingMethod = 'Cash on Delivery',
    this.deliveryFee,
    this.itemsSubtotal,
    this.currentStatus = BookingStatus.pending,
    this.proofOfDeliveryUrls,
    this.customerPhone,
    this.orderRating,
  });
}
