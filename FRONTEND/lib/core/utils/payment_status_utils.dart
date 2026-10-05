import '../../data/data_source/dto/wallet/wallet_dto.dart';
import '../../domain/entities/transactions/transaction.dart';

class PaymentStatusUtils {
  PaymentStatusUtils._();

  static PaymentStatus fromOrderPaymentStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return PaymentStatus.paid;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
      case 'refund':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  static PaymentStatus fromWalletTransaction(WalletTransactionDto tx) {
    if (tx.status != null && tx.status!.isNotEmpty) {
      return fromOrderPaymentStatus(tx.status);
    }
    final blob =
        '${tx.type} ${tx.description} ${tx.reference}'.toLowerCase();
    if (blob.contains('refund')) return PaymentStatus.refunded;
    if (blob.contains('failed') || blob.contains('fail')) {
      return PaymentStatus.failed;
    }
    if (blob.contains('pending')) return PaymentStatus.pending;
    return PaymentStatus.paid;
  }

  static String label(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.pending:
        return 'Pending';
    }
  }
}
