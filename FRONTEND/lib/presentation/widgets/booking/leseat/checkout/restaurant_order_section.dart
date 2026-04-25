import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../domain/entities/booking/leseat/order_item.dart';
import '../../../../widgets/widgets.dart';

class RestaurantOrderSection extends StatelessWidget {
  final String restaurantName;
  final List<OrderItem> items;
  final Function(String itemId, int newQuantity) onQuantityChanged;
  final Function(String itemId) onRemove;
  final VoidCallback onAddMoreItems;

  const RestaurantOrderSection({
    super.key,
    required this.restaurantName,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            restaurantName,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),

          // Order Items
          ...items.map((item) => OrderItemCard(
                item: item,
                onQuantityChanged: (newQuantity) {
                  onQuantityChanged(item.id, newQuantity);
                },
                onRemove: () {
                  onRemove(item.id);
                },
              )),

          SizedBox(height: ResponsiveUtils.spacing(context, 8)),

          // Add More Items Button
          TextButton.icon(
            onPressed: onAddMoreItems,
            icon: Icon(
              Icons.add_circle_outline,
              size: ResponsiveUtils.fontSize(context, 20),
              color: const Color(0xFF5F2D82),
            ),
            label: Text(
              'Add more items',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5F2D82),
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
