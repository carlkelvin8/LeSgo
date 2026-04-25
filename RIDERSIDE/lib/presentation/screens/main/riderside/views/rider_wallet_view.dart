import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../widgets/widgets.dart';

class RiderWalletView extends StatelessWidget {
  const RiderWalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),

          // Extracted Wallet Card component
          const RiderWalletCard(),

          SizedBox(height: ResponsiveUtils.spacing(context, 32)),

          // Divider line below card
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Divider(color: Colors.grey.shade300, thickness: 1),
          ),

          SizedBox(height: ResponsiveUtils.spacing(context, 24)),

          // Extracted Action Items component
          const RiderWalletActionsSection(),

          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        ],
      ),
    );
  }
}
