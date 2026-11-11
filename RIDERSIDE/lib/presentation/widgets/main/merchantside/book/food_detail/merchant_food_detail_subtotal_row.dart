import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../core/utils/dark_aware_colors.dart';
import '../../../../../../core/utils/app_localization.dart';

class MerchantFoodDetailSubtotalRow extends StatelessWidget {
  final double subtotal;

  const MerchantFoodDetailSubtotalRow({
    super.key,
    required this.subtotal,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: ResponsiveUtils.spacing(context, 8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.tr('Subtotal:'),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: context.sub(Colors.grey.shade600),
            ),
          ),
          Text(
            'PHP ${subtotal.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w700,
              color: context.acc(const Color(0xFF5F2D82)),
            ),
          ),
        ],
      ),
    );
  }
}
