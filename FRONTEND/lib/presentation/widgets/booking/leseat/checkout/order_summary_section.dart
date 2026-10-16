import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';

class OrderSummarySection extends StatelessWidget {
  final double subtotal;
  final double delivery;
  final double discount;
  final double total;
  final int itemCount;
  final bool deliveryFeeUncertain;
  final String? deliveryFeeNote;
  final bool orderValueUncertain;
  final String? orderValueNote;

  const OrderSummarySection({
    super.key,
    required this.subtotal,
    required this.delivery,
    this.discount = 0,
    required this.total,
    required this.itemCount,
    this.deliveryFeeUncertain = false,
    this.deliveryFeeNote,
    this.orderValueUncertain = false,
    this.orderValueNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
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
              color: AppColors.foreground(context, Colors.black87),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          
          _buildSummaryRow(
            context,
            'Subtotal',
            orderValueUncertain && subtotal <= 0
                ? 'TBD'
                : 'PHP ${subtotal.toStringAsFixed(2)}',
          ),
          if (orderValueNote != null) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              orderValueNote!,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 11),
                color: AppColors.foreground(context, Colors.grey[600]!),
                height: 1.35,
              ),
            ),
          ],
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          
          _buildSummaryRow(
            context,
            'Delivery',
            deliveryFeeUncertain && delivery <= 0
                ? 'TBD'
                : 'PHP ${delivery.toStringAsFixed(2)}',
          ),
          if (deliveryFeeNote != null) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              deliveryFeeNote!,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 11),
                color: AppColors.foreground(context, Colors.grey[600]!),
                height: 1.35,
              ),
            ),
          ],
          if (discount > 0) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            _buildSummaryRow(
              context,
              'Discount',
              '-PHP ${discount.toStringAsFixed(2)}',
              isDiscount: true,
            ),
          ],
          
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.spacing(context, 12),
            ),
            child: Divider(color: AppColors.border(context, Colors.grey[300]!), height: 1),
          ),
          
          _buildSummaryRow(
            context,
            orderValueUncertain ? 'Total ($itemCount items, est.)' : 'Total ($itemCount items)',
            orderValueUncertain && total <= 0
                ? 'TBD'
                : 'PHP ${total.toStringAsFixed(2)}',
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
    bool isDiscount = false,
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
            color: isDiscount ? Colors.red : (isTotal ? AppColors.foreground(context, Colors.black87) : AppColors.foreground(context, Colors.grey[600]!)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, isTotal ? 14 : 13),
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: isDiscount ? Colors.red : AppColors.foreground(context, Colors.black87),
          ),
        ),
      ],
    );
  }
}
