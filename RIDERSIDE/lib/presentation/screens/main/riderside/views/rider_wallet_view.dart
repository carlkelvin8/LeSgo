import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../../../core/constants/routers/app_router.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/riderside/rider_wallet_provider.dart';
import '../../../../widgets/main/riderside/wallet/rider_wallet_low_balance_banner.dart';
import '../../../../widgets/widgets.dart';

class RiderWalletView extends ConsumerWidget {
  const RiderWalletView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(riderWalletProvider);

    return RefreshIndicator(
      color: const Color(0xFF5F2D82),
      onRefresh: () => ref.read(riderWalletProvider.notifier).loadWallet(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveUtils.scrollPaddingWithBottomNav(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: ResponsiveUtils.spacing(context, 24)),
            const RiderWalletCard(),
            if (wallet.showLowBalanceWarning) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              RiderWalletLowBalanceBanner(balance: wallet.balance),
            ],
            if (wallet.error != null) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.horizontalPadding(context),
                ),
                child: Text(
                  wallet.error!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
            SizedBox(height: ResponsiveUtils.spacing(context, 32)),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.horizontalPadding(context),
              ),
              child: Divider(color: Colors.grey.shade300, thickness: 1),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 24)),
            const RiderWalletActionsSection(),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.horizontalPadding(context),
              ),
              child: InkWell(
                onTap: () =>
                    AppRouter.push(context, MainRoutes.riderScheduledPayout),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(
                    ResponsiveUtils.spacing(context, 16),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F2D82).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF5F2D82).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        color: const Color(0xFF5F2D82),
                        size: 24,
                      ),
                      SizedBox(
                        width: ResponsiveUtils.spacing(context, 12),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scheduled Payout',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontWeight: FontWeight.w700,
                                fontSize:
                                    ResponsiveUtils.fontSize(context, 14),
                                color: const Color(0xFF5F2D82),
                              ),
                            ),
                            SizedBox(
                              height:
                                  ResponsiveUtils.spacing(context, 2),
                            ),
                            Text(
                              'Set up recurring or one-time auto-payouts',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize:
                                    ResponsiveUtils.fontSize(context, 12),
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF5F2D82),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          ],
        ),
      ),
    );
  }
}
