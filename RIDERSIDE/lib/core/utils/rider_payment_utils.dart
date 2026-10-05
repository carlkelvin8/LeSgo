/// Payment helpers for rider order flows.
class RiderPaymentUtils {
  RiderPaymentUtils._();

  static bool isCashPayment(String? paymentMethod) {
    if (paymentMethod == null || paymentMethod.trim().isEmpty) return false;
    final normalized = paymentMethod.toLowerCase();
    return normalized.contains('cash') ||
        normalized.contains('cod') ||
        normalized.contains('delivery') && normalized.contains('cash');
  }

  static String formatCollectionLabel(String? billingAmount) {
    if (billingAmount == null || billingAmount.trim().isEmpty) {
      return 'Collect cash from customer';
    }
    return 'Collect $billingAmount from customer';
  }
}
