import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../data/data_source/dto/merchant/order_dto.dart';

/// Shows the estimated prep time based on number of items in the order.
/// Formula: 5 min base + 2 min per item.
class MerchantPrepTimeEstimate extends StatelessWidget {
  final OrderDto order;

  const MerchantPrepTimeEstimate({super.key, required this.order});

  int get _estimatedMinutes {
    final itemCount = order.orderItems?.fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        ) ??
        1;
    return 5 + (2 * itemCount);
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _estimatedMinutes;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCE93D8)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: const Color(0xFF7B1FA2),
            size: ResponsiveUtils.fontSize(context, 20),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Prep Time',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: const Color(0xFF7B1FA2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                Text(
                  '~$minutes minutes (${order.orderItems?.fold<int>(0, (s, i) => s + i.quantity) ?? 0} items)',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4A148C),
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
