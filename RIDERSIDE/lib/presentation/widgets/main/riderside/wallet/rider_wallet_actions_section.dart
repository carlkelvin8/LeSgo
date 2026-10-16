import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../screens/main/riderside/rider_wallet_history_screen.dart';
import '../../../../provider/main/riderside/rider_wallet_provider.dart';
import '../more/rider_more_components.dart';
import 'rider_top_up_dialog.dart';
import 'rider_wallet_withdraw_dialog.dart';

class RiderWalletActionsSection extends ConsumerWidget {
  const RiderWalletActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(riderWalletProvider);
    final lang = ref.watch(appLanguageProvider);
    String t(String key) => AppLocalization.translate(key, lang);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MoreSectionHeading(title: t('wallet_quick_actions')),
        MoreMenuGroup(
          children: [
            MoreMenuRow(
              icon: Icons.add_rounded,
              accent: const Color(0xFF168666),
              title: t('top_up'),
              subtitle: t('wallet_topup_methods'),
              onTap: () => showDialog(
                context: context,
                builder: (_) => RiderTopUpDialog(parentContext: context),
              ),
            ),
            MoreMenuRow(
              icon: Icons.south_west_rounded,
              accent: const Color(0xFF3976C4),
              title: t('withdraw'),
              subtitle: t(
                wallet.isProviderLinked('gcash') ||
                        wallet.isProviderLinked('maya')
                    ? 'send_to_gcash_maya'
                    : 'link_gcash_maya_first',
              ),
              onTap: () => showDialog(
                context: context,
                builder: (_) => RiderWalletWithdrawDialog(
                  parentContext: context,
                  availableBalance: ref.read(riderWalletProvider).balance,
                ),
              ),
            ),
            MoreMenuRow(
              icon: Icons.receipt_long_outlined,
              title: t('history'),
              subtitle: t('wallet_history_subtitle'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RiderWalletHistoryScreen(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
