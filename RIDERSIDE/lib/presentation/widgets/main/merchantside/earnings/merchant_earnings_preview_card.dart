import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_earnings_provider.dart';

class MerchantEarningsPreviewCard extends ConsumerWidget {
  const MerchantEarningsPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthAsync = ref.watch(merchantMonthEarningsProvider);
    final allTimeAsync = ref.watch(merchantAllTimeEarningsProvider);

    final monthLabel = monthAsync.when(
      loading: () => '...',
      error: (_, __) => '₱0.00',
      data: (amount) => formatMerchantPeso(amount),
    );
    final allTimeLabel = allTimeAsync.when(
      loading: () => '...',
      error: (_, __) => '₱0.00',
      data: (amount) => formatMerchantPeso(amount),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D9F5)),
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveUtils.spacing(context, 44),
            height: ResponsiveUtils.spacing(context, 44),
            decoration: BoxDecoration(
              color: const Color(0xFF5F2D82),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.payments_outlined,
              color: Colors.white,
              size: ResponsiveUtils.fontSize(context, 24),
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restaurant Earnings',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 15),
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Text(
                  'This Month: $monthLabel',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  'All Time: $allTimeLabel',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              AppRouter.push(context, MainRoutes.merchantEarnings);
            },
            child: Text(
              'View',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5F2D82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
