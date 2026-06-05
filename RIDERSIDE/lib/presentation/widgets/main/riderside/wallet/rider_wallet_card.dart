import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/riderside/rider_wallet_provider.dart';

class RiderWalletCard extends ConsumerWidget {
  const RiderWalletCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(riderWalletProvider);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: GestureDetector(
        onTap: wallet.isLoading
            ? null
            : () => ref.read(riderWalletProvider.notifier).loadWallet(),
        child: Container(
        width: double.infinity,
        height: ResponsiveUtils.imageHeight(context, 200),
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
                child: wallet.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCardText(
                            context,
                            'Balance',
                            wallet.balanceFormatted,
                          ),
                          const Spacer(),
                          _buildCardText(
                            context,
                            'Total top-ups',
                            wallet.depositFormatted,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildCardText(BuildContext context, String label, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 16),
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 28),
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
