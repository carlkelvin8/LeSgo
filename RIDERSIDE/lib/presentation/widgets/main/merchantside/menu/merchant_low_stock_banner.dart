import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_low_stock_provider.dart';

/// Warning banner shown at the top of the menu view when items are low stock.
class MerchantLowStockBanner extends ConsumerWidget {
  const MerchantLowStockBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockItems = ref.watch(merchantLowStockItemsProvider);

    if (lowStockItems.isEmpty) return const SizedBox.shrink();

    final itemNames = lowStockItems.take(3).map((e) => e.name).join(', ');
    final extraCount = lowStockItems.length - 3;
    final displayText = extraCount > 0
        ? '$itemNames +$extraCount more'
        : itemNames;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 10)),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade800,
            size: ResponsiveUtils.fontSize(context, 20),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low Stock Alert (${lowStockItems.length} items)',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade900,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Text(
                  displayText,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 11),
                    color: Colors.orange.shade800,
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
