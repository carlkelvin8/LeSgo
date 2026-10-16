import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

/// Reusable payment method selector widget
/// Currently supports COD (Cash on Delivery) as primary method
/// Optional card payments via payment gateway (GCash/PayMaya/bank hidden in UI).
class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final Function(String) onMethodChanged;
  final bool enabled;
  final double? walletBalance;
  final bool walletBalanceVisible;
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
    this.walletBalanceVisible = true,
    this.minimumWalletAmount,
    this.showWallet = false,
    this.showDigitalPayments = false,
  });

  bool get _walletHasSufficientBalance {
    final balance = walletBalance ?? 0;
    final required = minimumWalletAmount ?? 0.01;
    return balance >= required;
  }

  String get _walletBalanceLabel {
    if (!walletBalanceVisible) return 'Balance: ••••••';
    final balance = walletBalance ?? 0;
    if (_walletHasSufficientBalance) {
      return 'Balance: ₱${balance.toStringAsFixed(2)}';
    }
    return 'Insufficient balance (₱${balance.toStringAsFixed(2)})';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.horizontalPadding(context),
      ),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: RadioGroup<String>(
        groupValue: selectedMethod,
        onChanged: (v) {
          if (enabled && v != null) onMethodChanged(v);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Section Title
          Row(
            children: [
              Icon(
                Icons.payment,
                size: ResponsiveUtils.fontSize(context, 20),
                color: AppColors.accent(context, Color(0xFF5F2D82)),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 8)),
              Text(
                'Payment Method',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground(context, Colors.black87),
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
                  ? _walletBalanceLabel
                  : 'Digital wallet payment',
              icon: Icons.account_balance_wallet,
              iconColor: AppColors.accent(context, Color(0xFF5F2D82)),
              enabled: enabled && _walletHasSufficientBalance,
            ),
          ],

          if (showDigitalPayments) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            _buildPaymentOption(
              context: context,
              value: 'xendit',
              title: 'Online Payment',
              subtitle: 'Pay via GCash, Maya, or Credit/Debit Card',
              icon: Icons.phone_android,
              iconColor: const Color(0xFF0070F3),
              enabled: enabled,
            ),
          ],
        ],
      ),
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
              ? AppColors.accent(context, Color(0xFF5F2D82)).withValues(alpha: 0.05)
              : AppColors.surface(context, Colors.grey.shade50),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.accent(context, Color(0xFF5F2D82))
                : AppColors.border(context, Colors.grey.shade300),
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
                    : AppColors.surface(context, Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: ResponsiveUtils.fontSize(context, 24),
                color: enabled ? iconColor : AppColors.foreground(context, Colors.grey),
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
                      color: enabled ? AppColors.foreground(context, Colors.black87) : AppColors.foreground(context, Colors.grey),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: enabled ? AppColors.foreground(context, Colors.grey.shade600) : AppColors.foreground(context, Colors.grey),
                    ),
                  ),
                ],
              ),
            ),

            // Radio Button
            Radio<String>(
              value: value,
              activeColor: AppColors.accent(context, const Color(0xFF5F2D82)),
            ),
          ],
        ),
      ),
    );
  }
}
