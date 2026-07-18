/// LesPay top-up fee: 1.5% of the wallet credit amount (paid on top).
class LespayTopupFee {
  static const double feeRate = 0.015;

  final double walletAmount;
  final double feeAmount;
  final double totalCharge;

  const LespayTopupFee({
    required this.walletAmount,
    required this.feeAmount,
    required this.totalCharge,
  });

  factory LespayTopupFee.calculate(double walletAmount) {
    final fee = _round2(walletAmount * feeRate);
    final total = _round2(walletAmount + fee);
    return LespayTopupFee(
      walletAmount: _round2(walletAmount),
      feeAmount: fee,
      totalCharge: total,
    );
  }

  static double _round2(double value) => (value * 100).roundToDouble() / 100;
}
