/// Merchant-facing payment labels for order and wallet UI.
class MerchantPaymentUtils {
  MerchantPaymentUtils._();

  static String methodLabel(String? method) {
    switch ((method ?? 'cash').toLowerCase()) {
      case 'wallet':
        return 'LesPay Wallet';
      case 'xendit':
      case 'card':
        return 'Online Payment';
      case 'gcash':
        return 'GCash';
      case 'maya':
        return 'Maya';
      case 'cash':
      default:
        return 'Cash on Delivery';
    }
  }

  static String statusLabel(String? status) {
    switch ((status ?? 'pending').toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  static bool isOnlinePayment(String? method) {
    final normalized = (method ?? '').toLowerCase();
    return normalized == 'xendit' ||
        normalized == 'card' ||
        normalized == 'gcash' ||
        normalized == 'maya' ||
        normalized == 'wallet';
  }

  /// Mirrors OrderSettlementService::isOnlinePaid on the backend: the store
  /// wallet is credited only for online methods with payment_status 'paid'.
  static bool creditsMerchantWallet(String? method, String? status) {
    if (!isOnlinePayment(method)) return false;
    return (status ?? '').toLowerCase() == 'paid';
  }
}
