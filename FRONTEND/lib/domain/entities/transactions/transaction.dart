class Transaction {
  final String id;
  final String serviceName;
  final int serviceId;
  final String date;
  final String pickupLocation;
  final String dropoffLocation;
  final double amount;
  final TransactionStatus status;
  final String rawStatus;
  final List<TransactionItem>? items; // Added for item details

  Transaction({
    required this.id,
    required this.serviceName,
    required this.serviceId,
    required this.date,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.amount,
    required this.status,
    required this.rawStatus,
    this.items,
  });
}

class TransactionItem {
  final String name;
  final int quantity;
  final double? price;
  final String? unit;

  TransactionItem({
    required this.name,
    required this.quantity,
    this.price,
    this.unit,
  });
}

enum TransactionStatus {
  completed,
  pending,
  cancelled,
}
