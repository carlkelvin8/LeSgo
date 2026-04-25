import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class MerchantFoodDetailQuantityBar extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const MerchantFoodDetailQuantityBar({
    super.key,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: ResponsiveUtils.spacing(context, 8),
      ),
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.spacing(context, 8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quantity:',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: onDecrease,
                  child: Container(
                    width: ResponsiveUtils.spacing(context, 32),
                    height: ResponsiveUtils.spacing(context, 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.spacing(context, 6),
                      ),
                    ),
                    child: const Icon(Icons.remove, size: 18),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                Text(
                  quantity.toString(),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                GestureDetector(
                  onTap: onIncrease,
                  child: Container(
                    width: ResponsiveUtils.spacing(context, 32),
                    height: ResponsiveUtils.spacing(context, 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5F2D82),
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.spacing(context, 6),
                      ),
                    ),
                    child: const Icon(Icons.add, size: 18, color: Colors.white),
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
