class LestransportBooking {
  final String senderName;
  final String senderContactNumber;
  final String senderAddress;
  final DeliveryMethod deliveryMethod;
  final String? branchAddress;
  final double shippingFee;
  final double standardDeliveryFee;

  LestransportBooking({
    required this.senderName,
    required this.senderContactNumber,
    required this.senderAddress,
    required this.deliveryMethod,
    this.branchAddress,
    this.shippingFee = 10.00,
    this.standardDeliveryFee = 20.00,
  });

  double get totalOrder => shippingFee + standardDeliveryFee;

  LestransportBooking copyWith({
    String? senderName,
    String? senderContactNumber,
    String? senderAddress,
    DeliveryMethod? deliveryMethod,
    String? branchAddress,
    double? shippingFee,
    double? standardDeliveryFee,
  }) {
    return LestransportBooking(
      senderName: senderName ?? this.senderName,
      senderContactNumber: senderContactNumber ?? this.senderContactNumber,
      senderAddress: senderAddress ?? this.senderAddress,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      branchAddress: branchAddress ?? this.branchAddress,
      shippingFee: shippingFee ?? this.shippingFee,
      standardDeliveryFee: standardDeliveryFee ?? this.standardDeliveryFee,
    );
  }
}

enum DeliveryMethod {
  pickupDoorToDoor,
  padalaToBranch,
}

extension DeliveryMethodExtension on DeliveryMethod {
  String get displayName {
    switch (this) {
      case DeliveryMethod.pickupDoorToDoor:
        return 'Pickup Door-to-door';
      case DeliveryMethod.padalaToBranch:
        return 'Padala by going to the branch';
    }
  }
}
