import 'package:lesgo/presentation/widgets/booking/common/order_design.dart';
import 'package:lesgo/core/utils/money.dart';
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

  /// Cash wording differs per service (a ride is paid to the driver, not on delivery).
  final String cashTitle;
  final String cashSubtitle;

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
    this.cashTitle = 'Cash on Delivery',
    this.cashSubtitle = 'Pay with cash when order arrives',
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
      return 'Balance: ${Money.format(balance)}';
    }
    return 'Insufficient balance (${Money.format(balance)})';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
      ),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: OrderDesign.receipt(context),
      child: RadioGroup<String>(
        groupValue: selectedMethod,
        onChanged: (v) {
          if (enabled && v != null) onMethodChanged(v);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OrderSectionHeading(
              'Payment Method',
              icon: Icons.payments_outlined,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),

            // Cash on Delivery (Primary Method)
            _buildPaymentOption(
              context: context,
              value: 'cash',
              title: cashTitle,
              subtitle: cashSubtitle,
              icon: Icons.local_atm_outlined,
              enabled: enabled,
            ),

            // Wallet (Optional - for future use)
            if (showWallet) ...[
              Divider(height: 10, color: OrderDesign.line(context)),
              _buildPaymentOption(
                context: context,
                value: 'wallet',
                title: 'LesPay Wallet',
                subtitle: walletBalance != null
                    ? _walletBalanceLabel
                    : 'Digital wallet payment',
                icon: Icons.account_balance_wallet,
                enabled: enabled && _walletHasSufficientBalance,
              ),
            ],

            if (showDigitalPayments) ...[
              Divider(height: 10, color: OrderDesign.line(context)),
              _buildPaymentOption(
                context: context,
                value: 'xendit',
                title: 'Online Payment',
                subtitle: 'Pay via GCash, Maya, or Credit/Debit Card',
                icon: Icons.credit_card_rounded,
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
    required bool enabled,
  }) {
    final isSelected = selectedMethod == value;
    final emphasize = enabled && isSelected;

    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: enabled ? () => onMethodChanged(value) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: emphasize ? OrderDesign.tint(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            OrderIcon(icon, muted: !enabled, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? colors.onSurface
                          : colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      height: 1.35,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                Radio<String>(
                  value: value,
                  activeColor: emphasize
                      ? Colors.transparent
                      : OrderDesign.accent(context),
                ),
                if (emphasize)
                  IgnorePointer(
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 22,
                      color: OrderDesign.accent(context),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
