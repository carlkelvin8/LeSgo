import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';

class RestaurantCartBar extends StatelessWidget {
  final int itemCount;
  final double total;
  final VoidCallback onViewCart;

  const RestaurantCartBar({
    super.key,
    required this.itemCount,
    required this.total,
    required this.onViewCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.horizontalPadding(context),
        vertical: ResponsiveUtils.spacing(context, 16),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF5F2D82),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cart Icon with Count
            Container(
              width: ResponsiveUtils.spacing(context, 40),
              height: ResponsiveUtils.spacing(context, 40),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  itemCount.toString(),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5F2D82),
                  ),
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),

            // View Cart Text
            Expanded(
              child: GestureDetector(
                onTap: onViewCart,
                child: Text(
                  'View Cart',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Total Price
            Text(
              '₱${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 18),
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
