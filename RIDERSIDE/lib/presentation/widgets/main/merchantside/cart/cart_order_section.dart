import 'package:flutter/material.dart';

import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/cart/cart_provider.dart';
import 'cart_item_card.dart';

class CartOrderSection extends StatelessWidget {
  final List<CartItem> items;
  final ValueChanged<String> onDecrease;
  final ValueChanged<String> onIncrease;
  final ValueChanged<String>? onRemove;
  final VoidCallback onAddMoreItems;

  const CartOrderSection({
    super.key,
    required this.items,
    required this.onDecrease,
    required this.onIncrease,
    this.onRemove,
    required this.onAddMoreItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...items.map((item) {
            return Padding(
              padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 10)),
              child: Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.delete, color: Colors.red.shade700),
                ),
                onDismissed: (_) => onRemove?.call(item.id),
                child: CartItemCard(
                  name: item.name,
                  unitPrice: item.unitPrice,
                  quantity: item.quantity,
                  onDecrease: () {
                    if (item.quantity <= 1) {
                      onRemove?.call(item.id);
                    } else {
                      onDecrease(item.id);
                    }
                  },
                  onIncrease: () => onIncrease(item.id),
                  showDeleteAtMin: item.quantity <= 1,
                ),
              ),
            );
          }),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          GestureDetector(
            onTap: onAddMoreItems,
            child: Row(
              children: [
                const Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: Color(0xFF6B3A96),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                Text(
                  'Add more items',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B3A96),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
