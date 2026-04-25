import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import 'rider_wallet_action_item.dart';

class RiderWalletActionsSection extends StatelessWidget {
  const RiderWalletActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: const Column(
        children: [
          RiderWalletActionItem(
            iconAsset: 'assets/images/wallet/Plus.svg',
            title: 'Top up',
          ),
          RiderWalletActionItem(
            iconAsset: 'assets/images/wallet/Minus.svg',
            title: 'Withdraw',
          ),
          RiderWalletActionItem(
            iconAsset: 'assets/images/wallet/Maya.svg',
            title: 'Link PayMaya Account',
          ),
          RiderWalletActionItem(
            iconAsset: 'assets/images/wallet/Gcash.svg',
            title: 'Link Gcash Account',
          ),
          RiderWalletActionItem(
            iconAsset: 'assets/images/wallet/Bank.svg',
            title: 'History',
          ),
        ],
      ),
    );
  }
}
