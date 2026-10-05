import 'package:flutter/material.dart';
import '../../payment/booking_payment_method_section.dart';

/// Payment section widget specifically for LesGo service.
class LesgoPaymentSection extends StatelessWidget {
  const LesgoPaymentSection({
    super.key,
    required this.paymentMethod,
    required this.onPaymentChanged,
    this.minimumAmount,
  });

  final String paymentMethod;
  final ValueChanged<String?> onPaymentChanged;
  final double? minimumAmount;

  @override
  Widget build(BuildContext context) {
    return BookingPaymentMethodSection(
      selectedMethod: paymentMethod,
      onMethodChanged: (method) => onPaymentChanged(method),
      minimumAmount: minimumAmount,
    );
  }
}
