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
  });
}

enum TransactionStatus {
  completed,
  pending,
  cancelled,
}
