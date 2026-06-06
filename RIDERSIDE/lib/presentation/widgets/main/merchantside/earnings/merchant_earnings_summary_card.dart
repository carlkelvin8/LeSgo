import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_earnings_provider.dart';

class MerchantEarningsSummaryCard extends StatelessWidget {
  final double totalEarnings;
  final double pendingEarnings;
  final int completedOrders;
  final int pendingOrders;

  const MerchantEarningsSummaryCard({
    super.key,
    required this.totalEarnings,
    required this.pendingEarnings,
    required this.completedOrders,
    required this.pendingOrders,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.spacing(context, 24),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5F2D82).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.spacing(context, 24),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.asset(
                  'assets/images/wallet/Background.svg',
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Earnings',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      formatMerchantPeso(totalEarnings),
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 32),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                    Row(
                      children: [
                        Expanded(
                          child: _metric(
                            context,
                            label: 'Completed',
                            value: '$completedOrders orders',
                          ),
                        ),
                        Expanded(
                          child: _metric(
                            context,
                            label: 'Pending',
                            value: formatMerchantPeso(pendingEarnings),
                          ),
                        ),
                      ],
                    ),
                    if (pendingOrders > 0) ...[
                      SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                      Text(
                        '$pendingOrders active order${pendingOrders == 1 ? '' : 's'} not yet completed',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 12),
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, {required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
