import 'package:lesgo/core/theme/app_colors.dart';
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
    final itemCount = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: ResponsiveUtils.spacing(context, 34),
                height: ResponsiveUtils.spacing(context, 34),
                decoration: BoxDecoration(
                  color: AppColors.surface(context, Color(0xFFEEDDFD)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.storefront,
                  color: AppColors.accent(context, Color(0xFF5F2D82)),
                  size: ResponsiveUtils.fontSize(context, 18),
                ),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantName,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w800,
                        color: AppColors.foreground(context, Colors.black87),
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                    Text(
                      '$itemCount item${itemCount == 1 ? '' : 's'} from this restaurant',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: AppColors.foreground(context, Colors.grey[500]!),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'PHP ${subtotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent(context, Color(0xFF5F2D82)),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.spacing(context, 12),
            ),
            child: Divider(height: 1, color: AppColors.border(context, Colors.grey[200]!)),
          ),

          // Order Items
          ...items.map(
            (item) => OrderItemCard(
              item: item,
              onQuantityChanged: (newQuantity) {
                onQuantityChanged(item.id, newQuantity);
              },
              onRemove: () {
                onRemove(item.id);
              },
            ),
          ),

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
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }
}
