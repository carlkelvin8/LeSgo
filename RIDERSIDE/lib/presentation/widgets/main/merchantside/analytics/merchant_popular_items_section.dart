import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_analytics_provider.dart';

/// Displays the top 5 most ordered items from analytics data.
class MerchantPopularItemsSection extends ConsumerWidget {
  const MerchantPopularItemsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(merchantAnalyticsSummaryProvider);

    return analyticsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        final topItems = summary.topItems.take(5).toList();
        if (topItems.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department_outlined,
                    color: const Color(0xFFFF6D00),
                    size: ResponsiveUtils.fontSize(context, 20),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    'Popular Items',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 15),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              ...topItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: ResponsiveUtils.spacing(context, 10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: ResponsiveUtils.spacing(context, 26),
                        height: ResponsiveUtils.spacing(context, 26),
                        decoration: BoxDecoration(
                          color: _medalColor(index).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                            fontWeight: FontWeight.w800,
                            color: _medalColor(index),
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.spacing(context, 10)),
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.spacing(context, 8),
                          vertical: ResponsiveUtils.spacing(context, 4),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${item.quantitySold} sold',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 11),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5F2D82),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Color _medalColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFB300); // Gold
      case 1:
        return const Color(0xFF78909C); // Silver
      case 2:
        return const Color(0xFFBF360C); // Bronze
      default:
        return const Color(0xFF5F2D82); // Purple
    }
  }
}
