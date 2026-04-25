import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';

class OrderSummarySection extends StatelessWidget {
  final double subtotal;
  final double delivery;
  final double total;
  final int itemCount;

  const OrderSummarySection({
    super.key,
    required this.subtotal,
    required this.delivery,
    required this.total,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          
          _buildSummaryRow(
            context,
            'Subtotal',
            'PHP ${subtotal.toStringAsFixed(2)}',
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          
          _buildSummaryRow(
            context,
            'Delivery',
            'PHP ${delivery.toStringAsFixed(2)}',
          ),
          
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.spacing(context, 12),
            ),
            child: Divider(color: Colors.grey[300], height: 1),
          ),
          
          _buildSummaryRow(
            context,
            'Total ($itemCount items)',
            'PHP ${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, isTotal ? 14 : 13),
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: isTotal ? Colors.black87 : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, isTotal ? 14 : 13),
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
