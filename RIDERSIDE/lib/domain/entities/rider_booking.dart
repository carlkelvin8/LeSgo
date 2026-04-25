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
}

extension BookingStatusX on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.cooking:
        return 'Cooking';
      case BookingStatus.forPickUp:
        return 'For Pick Up';
      case BookingStatus.forDelivery:
        return 'For Delivery';
      case BookingStatus.delivered:
        return 'Delivered';
      case BookingStatus.toBuy:
        return 'To Buy';
      case BookingStatus.onTheWay:
        return 'On The Way';
      case BookingStatus.onTheWayGoing:
        return 'On The Way\n(Going)';
      case BookingStatus.driverHasArrived:
        return 'Driver Has\nArrived';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.complete:
        return 'Complete';
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
      default:
        return null;
    }
  }
}

extension BookingCategoryStatuses on BookingCategory {
  List<BookingStatus> get statuses {
    switch (this) {
      case BookingCategory.lesEat:
        return [
          BookingStatus.pending,
          BookingStatus.cooking,
          BookingStatus.forPickUp,
          BookingStatus.forDelivery,
          BookingStatus.delivered,
        ];
      case BookingCategory.lesBuy:
        return [
          BookingStatus.pending,
          BookingStatus.toBuy,
          BookingStatus.forDelivery,
          BookingStatus.delivered,
        ];
      case BookingCategory.lesRide:
        return [
          BookingStatus.onTheWay,
          BookingStatus.onTheWayGoing,
          BookingStatus.driverHasArrived,
          BookingStatus.inProgress,
          BookingStatus.complete,
        ];
    }
  }
}

class RiderBooking {
  final String id;
  final String restaurantName;
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
  final BookingStatus currentStatus;
  final List<String>? proofOfDeliveryUrls;
  final String? customerPhone;

  const RiderBooking({
    required this.id,
    required this.restaurantName,
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
    this.currentStatus = BookingStatus.pending,
    this.proofOfDeliveryUrls,
    this.customerPhone,
  });
}
