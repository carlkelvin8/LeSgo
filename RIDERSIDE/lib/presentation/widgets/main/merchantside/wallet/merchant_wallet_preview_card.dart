import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_wallet_provider.dart';

class MerchantWalletPreviewCard extends ConsumerWidget {
  const MerchantWalletPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(merchantWalletProvider);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9B59F0), Color(0xFF5F2D82)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5F2D82).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveUtils.spacing(context, 44),
            height: ResponsiveUtils.spacing(context, 44),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
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
                  'LesPay E-Wallet',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 15),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Text(
                  wallet.isLoading
                      ? 'Loading balance...'
                      : wallet.balanceFormatted,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 18),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                Text(
                  'Online customer payments reflect here',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 11),
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              AppRouter.push(context, MainRoutes.merchantWallet);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
            ),
            child: Text(
              'View',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
