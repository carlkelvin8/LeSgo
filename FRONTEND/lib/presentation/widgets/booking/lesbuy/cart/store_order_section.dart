import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../domain/entities/booking/lesbuy/cart_item.dart';
import 'store_cart_item_card.dart';

class StoreOrderSection extends StatelessWidget {
  final String storeName;
  final List<LesbuyCartItem> items;
  final Function(int index, int newQuantity) onQuantityChanged;
  final Function(int index) onRemove;
  final VoidCallback onAddMoreItems;

  const StoreOrderSection({
    super.key,
    required this.storeName,
    required this.items,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onAddMoreItems,
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
            storeName,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w700,
              color: AppColors.foreground(context, Colors.black87),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),

          // Order Items
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return StoreCartItemCard(
              item: item,
              onQuantityChanged: (newQuantity) {
                onQuantityChanged(index, newQuantity);
              },
              onRemove: () {
                onRemove(index);
              },
            );
          }),

          SizedBox(height: ResponsiveUtils.spacing(context, 8)),

          // Add More Items Button
          TextButton.icon(
            onPressed: onAddMoreItems,
            icon: Icon(
              Icons.add_circle_outline,
              size: ResponsiveUtils.fontSize(context, 20),
              color: AppColors.accent(context, Color(0xFF5F2D82)),
            ),
            label: Text(
              'Add more items',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                fontWeight: FontWeight.w600,
                color: AppColors.accent(context, Color(0xFF5F2D82)),
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
