import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';

class CartPriceSummary extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final int itemCount;
  final double total;

  const CartPriceSummary({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.itemCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: ResponsiveUtils.spacing(context, 12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8E8E8)),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.spacing(context, 12),
          ),
        ),
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Summary',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            _SummaryRow(
              label: 'Subtotal',
              value: 'PHP ${subtotal.toStringAsFixed(2)}',
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            _SummaryRow(
              label: 'Delivery',
              value: 'PHP ${deliveryFee.toStringAsFixed(2)}',
            ),
            Divider(
              color: Colors.grey.shade300,
              height: ResponsiveUtils.spacing(context, 16),
            ),
            _SummaryRow(
              label: 'Total ($itemCount items)',
              value: 'PHP ${total.toStringAsFixed(2)}',
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 12,
      runSpacing: 4,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? const Color(0xFF2A2A2A) : const Color(0xFF747474),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: const Color(0xFF2A2A2A),
          ),
        ),
      ],
    );
  }
}
