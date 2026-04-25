import 'package:flutter/material.dart';
import '../../payment/payment_method_selector.dart';

class LesridePaymentSection extends StatelessWidget {
  const LesridePaymentSection({
    super.key,
    required this.paymentMethod,
    required this.onPaymentChanged,
  });

  final String paymentMethod;
  final ValueChanged<String?> onPaymentChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Use the new reusable PaymentMethodSelector
        PaymentMethodSelector(
          selectedMethod: paymentMethod,
          onMethodChanged: (method) => onPaymentChanged(method),
          enabled: true,
          showWallet: false, // Can enable for future wallet integration
          showDigitalPayments: false, // Can enable for GCash/PayMaya/Card
        ),
      ],
    );
  }
}
