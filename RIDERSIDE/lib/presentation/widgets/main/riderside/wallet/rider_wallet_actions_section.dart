import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../screens/main/riderside/rider_wallet_history_screen.dart';
import '../../../../provider/main/riderside/rider_wallet_provider.dart';
import 'rider_top_up_dialog.dart';
import 'rider_wallet_action_item.dart';
import 'rider_wallet_link_account_dialog.dart';
import 'rider_wallet_withdraw_dialog.dart';

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

  void _showLinkAccount(BuildContext context, String provider, String title) {
    showDialog<bool>(
      context: context,
      builder: (_) => RiderWalletLinkAccountDialog(
        parentContext: context,
        provider: provider,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(riderWalletProvider);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          RiderWalletActionItem(
            iconAsset: 'assets/images/wallet/Plus.svg',
            title: 'Top up',
            subtitle: 'GCash, Maya, or card via Xendit',
            onTap: () => _showTopUp(context),
          ),
          RiderWalletActionItem(
            iconAsset: 'assets/images/wallet/Minus.svg',
            title: 'Withdraw',
            subtitle: wallet.isProviderLinked('gcash') ||
                    wallet.isProviderLinked('maya')
                ? 'Send to linked GCash or Maya'
                : 'Link GCash or Maya first',
            onTap: () => _showWithdraw(context, ref),
          ),
          RiderWalletActionItem(
            iconAsset: 'assets/images/wallet/Maya.svg',
            title: 'Link PayMaya Account',
            subtitle: wallet.linkedAccountSubtitle('maya'),
            onTap: () => _showLinkAccount(context, 'maya', 'PayMaya'),
          ),
          RiderWalletActionItem(
            iconAsset: 'assets/images/wallet/Gcash.svg',
            title: 'Link Gcash Account',
            subtitle: wallet.linkedAccountSubtitle('gcash'),
            onTap: () => _showLinkAccount(context, 'gcash', 'GCash'),
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
