import 'package:flutter/material.dart';
import '../../payment/booking_payment_method_section.dart';

class LesridePaymentSection extends StatelessWidget {
  const LesridePaymentSection({
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
