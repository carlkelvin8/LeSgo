import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/riderside/rider_wallet_provider.dart';
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: ResponsiveUtils.spacing(context, 24)),
            const RiderWalletCard(),
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
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          ],
        ),
      ),
    );
  }
}
