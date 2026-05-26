import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

/// Reusable payment method selector widget
/// Currently supports COD (Cash on Delivery) as primary method
/// Infrastructure ready for digital payments (GCash, PayMaya, Card)
class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final Function(String) onMethodChanged;
  final bool enabled;
  final double? walletBalance;
  /// When set, LesPay is selectable only if balance >= this amount.
  final double? minimumWalletAmount;
  final bool showWallet;
  final bool showDigitalPayments;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
    this.enabled = true,
    this.walletBalance,
    this.minimumWalletAmount,
    this.showWallet = false,
    this.showDigitalPayments = false,
  });

  bool get _walletHasSufficientBalance {
    final balance = walletBalance ?? 0;
    final required = minimumWalletAmount ?? 0.01;
    return balance >= required;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.horizontalPadding(context),
      ),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Icon(
                Icons.payment,
                size: ResponsiveUtils.fontSize(context, 20),
                color: const Color(0xFF5F2D82),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 8)),
              Text(
                'Payment Method',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),

          // Cash on Delivery (Primary Method)
          _buildPaymentOption(
            context: context,
            value: 'cash',
            title: 'Cash on Delivery',
            subtitle: 'Pay with cash when order arrives',
            icon: Icons.money,
            iconColor: Colors.green,
            enabled: enabled,
          ),

          // Wallet (Optional - for future use)
          if (showWallet) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            _buildPaymentOption(
              context: context,
              value: 'wallet',
              title: 'LesPay Wallet',
              subtitle: walletBalance != null
                  ? _walletHasSufficientBalance
                      ? 'Balance: ₱${walletBalance!.toStringAsFixed(2)}'
                      : 'Insufficient balance (₱${walletBalance!.toStringAsFixed(2)})'
                  : 'Digital wallet payment',
              icon: Icons.account_balance_wallet,
              iconColor: const Color(0xFF5F2D82),
              enabled: enabled && _walletHasSufficientBalance,
            ),
          ],

          // Digital Payments (Optional - for future use)
          if (showDigitalPayments) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            _buildPaymentOption(
              context: context,
              value: 'gcash',
              title: 'GCash',
              subtitle: 'Pay with GCash e-wallet',
              icon: Icons.phone_android,
              iconColor: Colors.blue,
              enabled: enabled,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            _buildPaymentOption(
              context: context,
              value: 'paymaya',
              title: 'PayMaya',
              subtitle: 'Pay with PayMaya e-wallet',
              icon: Icons.phone_android,
              iconColor: Colors.green,
              enabled: enabled,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            _buildPaymentOption(
              context: context,
              value: 'card',
              title: 'Credit/Debit Card',
              subtitle: 'Pay with credit or debit card',
              icon: Icons.credit_card,
              iconColor: Colors.orange,
              enabled: enabled,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool enabled,
  }) {
    final isSelected = selectedMethod == value;

    return GestureDetector(
      onTap: enabled ? () => onMethodChanged(value) : null,
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5F2D82).withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5F2D82)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
              decoration: BoxDecoration(
                color: enabled
                    ? iconColor.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: ResponsiveUtils.fontSize(context, 24),
                color: enabled ? iconColor : Colors.grey,
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: enabled ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: enabled ? Colors.grey.shade600 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Radio Button
            Radio<String>(
              value: value,
              groupValue: selectedMethod,
              onChanged: enabled ? (String? newValue) {
                if (newValue != null) {
                  onMethodChanged(newValue);
                }
              } : null,
              activeColor: const Color(0xFF5F2D82),
            ),
          ],
        ),
      ),
    );
  }
}
