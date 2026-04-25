import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/booking/lesbuy/manual_order_provider.dart';

class ManualOrderSection extends StatelessWidget {
  final List<ManualOrderItem> items;
  final Function(String itemId) onIncrement;
  final Function(String itemId) onDecrement;
  final Function(String itemId) onRemove;
  final VoidCallback onAddMoreItems;

  const ManualOrderSection({
    super.key,
    required this.items,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onAddMoreItems,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

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
          // Header - just title, no icon
          Text(
            'Manual Order',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),

          // Manual Order Items
          ...items.asMap().entries.map(
            (entry) => _ManualOrderItemRow(
              index: entry.key + 1,
              item: entry.value,
              onIncrement: () => onIncrement(entry.value.id),
              onDecrement: () => onDecrement(entry.value.id),
              onRemove: () => onRemove(entry.value.id),
            ),
          ),

          SizedBox(height: ResponsiveUtils.spacing(context, 8)),

          // Price disclaimer
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 10)),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 14),
                SizedBox(width: ResponsiveUtils.spacing(context, 6)),
                Expanded(
                  child: Text(
                    'Prices TBD by rider',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 11),
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

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
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }
}

class _ManualOrderItemRow extends StatelessWidget {
  final int index;
  final ManualOrderItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _ManualOrderItemRow({
    required this.index,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
      child: Row(
        children: [
          // Small indent
          SizedBox(width: ResponsiveUtils.spacing(context, 8)),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. ${item.name}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Price TBD',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: onDecrement,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  color: Colors.grey[600],
                ),
                Text(
                  '${item.quantity}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: onIncrement,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  color: const Color(0xFF5F2D82),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
