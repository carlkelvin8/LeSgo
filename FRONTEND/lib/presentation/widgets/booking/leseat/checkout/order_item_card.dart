import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../common/media_image.dart';
import '../../../../../domain/entities/booking/leseat/order_item.dart';

class OrderItemCard extends StatelessWidget {
  final OrderItem item;
  final Function(int)? onQuantityChanged;
  final VoidCallback? onRemove;

  const OrderItemCard({
    super.key,
    required this.item,
    this.onQuantityChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image
          Container(
            width: ResponsiveUtils.spacing(context, 64),
            height: ResponsiveUtils.spacing(context, 64),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: MediaImage(
                imagePath: item.imagePath,
                fit: BoxFit.cover,
                placeholder: Icon(
                  Icons.restaurant,
                  color: Colors.grey[400],
                  size: ResponsiveUtils.fontSize(context, 32),
                ),
              ),
            ),
          ),

          SizedBox(width: ResponsiveUtils.spacing(context, 12)),

          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (item.optionsDisplay != null) ...[
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Text(
                    item.optionsDisplay!,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 11),
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Text(
                  'PHP ${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (onRemove != null)
                IconButton(
                  tooltip: 'Remove item',
                  icon: Icon(
                    Icons.delete_outline,
                    size: ResponsiveUtils.fontSize(context, 18),
                    color: Colors.red.shade400,
                  ),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: () {
                        if (item.quantity > 1) {
                          onQuantityChanged?.call(item.quantity - 1);
                        } else {
                          onRemove?.call();
                        }
                      },
                      padding:
                          EdgeInsets.all(ResponsiveUtils.spacing(context, 4)),
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.spacing(context, 8),
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: () =>
                          onQuantityChanged?.call(item.quantity + 1),
                      padding:
                          EdgeInsets.all(ResponsiveUtils.spacing(context, 4)),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
