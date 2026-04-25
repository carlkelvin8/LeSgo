import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../domain/entities/booking/lesbuy/cart_item.dart';

class StoreCartItemCard extends StatelessWidget {
  final LesbuyCartItem item;
  final Function(int newQuantity) onQuantityChanged;
  final VoidCallback onRemove;

  const StoreCartItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
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
              child: item.product.imagePath.toLowerCase().endsWith('.svg')
                  ? SvgPicture.asset(
                      item.product.imagePath,
                      fit: BoxFit.cover,
                      placeholderBuilder: (BuildContext context) => Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Icon(
                          Icons.shopping_bag,
                          color: Colors.grey[400],
                          size: ResponsiveUtils.fontSize(context, 32),
                        ),
                      ),
                    )
                  : Image.asset(
                      item.product.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.shopping_bag,
                          color: Colors.grey[400],
                          size: ResponsiveUtils.fontSize(context, 32),
                        );
                      },
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
                  item.product.name,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Text(
                  'PHP ${item.product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Quantity Controls
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
                      onQuantityChanged(item.quantity - 1);
                    } else {
                      onRemove();
                    }
                  },
                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 4)),
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
                  onPressed: () => onQuantityChanged(item.quantity + 1),
                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 4)),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
