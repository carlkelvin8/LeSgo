enum TransactionKind {
  order,
  wallet,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}

enum TransactionStatus {
  completed,
  pending,
  cancelled,
}

class Transaction {
  final String id;
  final TransactionKind kind;
  final String serviceName;
  final int serviceId;
  final String date;
  final String pickupLocation;
  final String dropoffLocation;
  final double amount;
  final TransactionStatus status;
  final String rawStatus;
  final PaymentStatus paymentStatus;
  final String? paymentMethod;
  final List<TransactionItem>? items;
  /// Wallet-only fields
  final String? walletDescription;
  final String? walletReference;
  final bool? isWalletCredit;

  Transaction({
    required this.id,
    this.kind = TransactionKind.order,
    required this.serviceName,
    this.serviceId = 0,
    required this.date,
    this.pickupLocation = '',
    this.dropoffLocation = '',
    required this.amount,
    required this.status,
    required this.rawStatus,
    this.paymentStatus = PaymentStatus.pending,
    this.paymentMethod,
    this.items,
    this.walletDescription,
    this.walletReference,
    this.isWalletCredit,
  });

  bool get isOrder => kind == TransactionKind.order;
  bool get isWallet => kind == TransactionKind.wallet;

  String get displayTitle =>
      isWallet ? (walletDescription ?? 'LesPay') : serviceName;

  String get displaySubtitle => isWallet
      ? (walletReference?.isNotEmpty == true ? walletReference! : 'Wallet')
      : 'Order #$id';
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
