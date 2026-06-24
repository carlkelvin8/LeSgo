import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/rider_wallet_policy.dart';

class RiderWalletLowBalanceBanner extends ConsumerWidget {
  final double balance;

  const RiderWalletLowBalanceBanner({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = RiderWalletPolicy.lowBalanceWarningMessage(balance);
    if (message.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.horizontalPadding(context),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.orange.shade800,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  color: Colors.orange.shade900,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
