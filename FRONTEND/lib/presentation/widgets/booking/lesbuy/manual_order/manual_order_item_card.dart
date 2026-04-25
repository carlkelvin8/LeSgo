import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/booking/lesbuy/manual_order_provider.dart';

class ManualOrderItemCard extends StatelessWidget {
  final ManualOrderItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const ManualOrderItemCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                if (item.description.isNotEmpty) ...[
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(width: ResponsiveUtils.spacing(context, 12)),

          // Quantity Controls
          Row(
            children: [
              // Decrement Button
              InkWell(
                onTap: onDecrement,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.remove,
                    size: 16,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Quantity Display
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  'x${item.quantity}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Increment Button
              InkWell(
                onTap: onIncrement,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F2D82),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),

          SizedBox(width: ResponsiveUtils.spacing(context, 8)),

          // Delete Button
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 4)),
              child: Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
