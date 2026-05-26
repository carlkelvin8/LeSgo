import 'package:flutter/material.dart';

import '../../../core/utils/lespay_topup_fee.dart';
import '../../../core/utils/responsive_utils.dart';

class TopUpFeeSummary extends StatelessWidget {
  final double walletAmount;

  const TopUpFeeSummary({super.key, required this.walletAmount});

  @override
  Widget build(BuildContext context) {
    if (walletAmount <= 0) return const SizedBox.shrink();

    final pricing = LespayTopupFee.calculate(walletAmount);
    final textStyle = TextStyle(
      fontFamily: 'TT Fors',
      fontSize: ResponsiveUtils.fontSize(context, 13),
      color: Colors.grey[800],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8DDF0)),
      ),
      child: Column(
        children: [
          _row(context, 'Amount to wallet', pricing.walletAmount, textStyle),
          SizedBox(height: ResponsiveUtils.spacing(context, 6)),
          _row(
            context,
            'Top-up fee (3%)',
            pricing.feeAmount,
            textStyle,
          ),
          Divider(height: ResponsiveUtils.spacing(context, 16)),
          _row(
            context,
            'Total to pay',
            pricing.totalCharge,
            textStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5F2D82),
            ),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    double value,
    TextStyle style, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          '₱${value.toStringAsFixed(2)}',
          style: style.copyWith(
            fontSize: isTotal
                ? ResponsiveUtils.fontSize(context, 15)
                : style.fontSize,
          ),
        ),
      ],
    );
  }
}
