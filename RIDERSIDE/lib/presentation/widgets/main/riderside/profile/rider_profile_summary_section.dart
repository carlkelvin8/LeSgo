import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/riderside/rider_main_nav_provider.dart';
import '../../../../provider/main/riderside/rider_mission_provider.dart';
import '../../../../provider/main/riderside/rider_orders_provider.dart';
import '../../../../provider/main/riderside/rider_wallet_provider.dart';

class RiderProfileSummarySection extends ConsumerWidget {
  const RiderProfileSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final wallet = ref.watch(riderWalletProvider);
    final missions = ref.watch(riderMissionProvider);
    final orders = ref.watch(riderOrdersProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);

    final missionInProgress = missions.missions
        .where((m) => !m.isCompleted && m.currentProgress > 0)
        .length;
    final claimable =
        missions.missions.where((m) => m.isCompleted && !m.rewardClaimed).length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalization.translate('overview', lang),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 15),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          if (wallet.showLowBalanceWarning)
            _AlertCard(
              icon: Icons.account_balance_wallet_outlined,
              color: Colors.orange,
              title: AppLocalization.translate('low_lespay_balance', lang),
              subtitle: wallet.lowBalanceWarningMessage,
              onTap: () =>
                  ref.read(riderNavProvider.notifier).navigateTo(RiderNavType.more),
            ),
          if (orders.activeOrder != null) ...[
            if (wallet.showLowBalanceWarning)
              SizedBox(height: ResponsiveUtils.spacing(context, 10)),
            _AlertCard(
              icon: Icons.delivery_dining,
              color: const Color(0xFF5F2D82),
              title: AppLocalization.translate('active_delivery', lang),
              subtitle:
                  'Order #${orders.activeOrder!.id} • ${orders.activeOrder!.status.replaceAll('_', ' ')}',
              onTap: null,
            ),
          ],
          if (claimable > 0) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 10)),
            _AlertCard(
              icon: Icons.card_giftcard,
              color: Colors.green,
              title: AppLocalization.translate('mission_reward_ready', lang),
              subtitle:
                  '$claimable reward${claimable == 1 ? '' : 's'} waiting to claim',
              onTap: null,
            ),
          ] else if (missionInProgress > 0) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 10)),
            _AlertCard(
              icon: Icons.flag_outlined,
              color: const Color(0xFF5F2D82),
              title: AppLocalization.translate('missions_in_progress', lang),
              subtitle: '$missionInProgress active mission${missionInProgress == 1 ? '' : 's'}',
              onTap: null,
            ),
          ],
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          _QuickLinkRow(
            icon: Icons.verified_user_outlined,
            label: AppLocalization.translate('document_verification', lang),
            onTap: () =>
                AppRouter.push(context, MainRoutes.riderDocuments),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _AlertCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
          child: Row(
            children: [
              Icon(icon, color: color),
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveUtils.fontSize(context, 13),
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF5F2D82)),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 14),
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
