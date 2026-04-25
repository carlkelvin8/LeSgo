import 'package:flutter/material.dart';
import '../../payment/payment_method_selector.dart';

/// Payment section widget specifically for LesGo service.
/// This is a separate component from LesRide to allow for
/// future customizations and additional fields.
class LesgoPaymentSection extends StatelessWidget {
  const LesgoPaymentSection({
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
