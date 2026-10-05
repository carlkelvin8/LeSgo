import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

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
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent(context, Color(0xFF5F2D82)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent(context, Color(0xFF5F2D82)).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewCart,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Cart Icon with Count
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration:  BoxDecoration(
                    color: AppColors.surface(context, Colors.white),
                    shape: BoxShape.circle,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_bag,
                        color: AppColors.accent(context, const Color(0xFF5F2D82)),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        itemCount.toString(),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent(context, const Color(0xFF5F2D82)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Items text and total
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 12,
                          color: AppColors.onAccent(context).withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '₱${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onAccent(context),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Cart',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onAccent(context),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: AppColors.onAccent(context),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
