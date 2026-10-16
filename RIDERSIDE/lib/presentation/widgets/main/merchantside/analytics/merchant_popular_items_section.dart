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

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: const Color(0xFFFF6D00),
                      size: ResponsiveUtils.fontSize(context, 16),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                    Text(
                      'Top Sellers',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 13),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF302B36),
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
                          width: ResponsiveUtils.spacing(context, 24),
                          height: ResponsiveUtils.spacing(context, 24),
                          decoration: BoxDecoration(
                            color: _rankColor(index).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 11),
                              fontWeight: FontWeight.w700,
                              color: _rankColor(index),
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
                              fontSize: ResponsiveUtils.fontSize(context, 12.5),
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF302B36),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.spacing(context, 8),
                            vertical: ResponsiveUtils.spacing(context, 4),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.quantitySold}',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 10.5),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8054A2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _rankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFB300); // Gold
      case 1:
        return const Color(0xFF78909C); // Silver
      case 2:
        return const Color(0xFFBF360C); // Bronze
      default:
        return const Color(0xFF8054A2); // Purple
    }
  }
}
