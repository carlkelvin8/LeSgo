import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';

class CartItemCard extends StatelessWidget {
  final String name;
  final double unitPrice;
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const CartItemCard({
    super.key,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: ResponsiveUtils.spacing(context, 54),
          height: ResponsiveUtils.spacing(context, 54),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEFE5),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            '🍕',
            style: TextStyle(fontSize: ResponsiveUtils.fontSize(context, 30)),
          ),
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF242424),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 2)),
              Text(
                'PHP ${unitPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8B8B8B),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 8)),
        Container(
          height: ResponsiveUtils.spacing(context, 42),
          padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.spacing(context, 10)),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            border: Border.all(color: const Color(0xFFE1E1E1)),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              _StepAction(symbol: '-', onTap: onDecrease),
              SizedBox(width: ResponsiveUtils.spacing(context, 14)),
              Text(
                '$quantity',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF242424),
                ),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 14)),
              _StepAction(symbol: '+', onTap: onIncrease),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepAction extends StatelessWidget {
  final String symbol;
  final VoidCallback onTap;

  const _StepAction({
    required this.symbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        symbol,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 18),
          fontWeight: FontWeight.w500,
          color: const Color(0xFF616161),
        ),
      ),
    );
  }
}
