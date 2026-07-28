import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../screens/main/riderside/rider_wallet_history_screen.dart';
import '../../../../provider/main/riderside/rider_wallet_provider.dart';
import 'rider_top_up_dialog.dart';
import 'rider_wallet_action_item.dart';
import 'rider_wallet_withdraw_dialog.dart';
import '../../../../../core/utils/app_localization.dart';

class RiderWalletActionsSection extends ConsumerWidget {
  const RiderWalletActionsSection({super.key});

  void _showTopUp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => RiderTopUpDialog(parentContext: context),
    );
  }

  void _showWithdraw(BuildContext context, WidgetRef ref) {
    final balance = ref.read(riderWalletProvider).balance;
    showDialog(
      context: context,
      builder: (_) => RiderWalletWithdrawDialog(
        parentContext: context,
        availableBalance: balance,
      ),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RiderWalletHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(riderWalletProvider);
    final lang = ref.watch(appLanguageProvider);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          RiderWalletActionItem(
            iconAsset: 'assets/images/wallet/Plus.svg',
            title: AppLocalization.translate('top_up', lang),
            subtitle: 'GCash, Maya, or card via PayMongo',
            onTap: () => _showTopUp(context),
          ),
          RiderWalletActionItem(
            iconAsset: 'assets/images/wallet/Minus.svg',
            title: AppLocalization.translate('withdraw', lang),
            subtitle: wallet.isProviderLinked('gcash') ||
                    wallet.isProviderLinked('maya')
                ? AppLocalization.translate('send_to_gcash_maya', lang)
                : AppLocalization.translate('link_gcash_maya_first', lang),
            onTap: () => _showWithdraw(context, ref),
          ),

          RiderWalletActionItem(
            iconAsset: 'assets/images/wallet/Bank.svg',
            title: 'History',
            subtitle: 'View LesPay credits and debits',
            onTap: () => _openHistory(context),
          ),
        ],
      ),
    );
  }
}
