/// LesGo platform fee on merchant → rider LeSpay transfers.
///
/// Commission is deducted from the gross amount before crediting the rider.
class MerchantTransferCommissionUtils {
  MerchantTransferCommissionUtils._();

  /// Platform share (10%) — deducted from amount sent to rider.
  static const double platformRate = 0.10;

  static double platformFee(double grossAmount) =>
      double.parse((grossAmount * platformRate).toStringAsFixed(2));

  static double riderReceives(double grossAmount) =>
      double.parse((grossAmount - platformFee(grossAmount)).toStringAsFixed(2));

  static String breakdownLabel(double grossAmount) {
    final fee = platformFee(grossAmount);
    final net = riderReceives(grossAmount);
    return 'Rider receives PHP ${net.toStringAsFixed(2)} · LesGo fee PHP ${fee.toStringAsFixed(2)}';
  }
}
