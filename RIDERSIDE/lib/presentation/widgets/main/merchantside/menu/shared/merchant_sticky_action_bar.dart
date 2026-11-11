import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../core/utils/dark_aware_colors.dart';

/// Shared bottom action bar padding for merchant form screens.
class MerchantStickyActionBar extends StatelessWidget {
  final Widget child;

  const MerchantStickyActionBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.surf(Colors.white),
        border: Border(top: BorderSide(color: context.brd(Colors.grey.shade200))),
      ),
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.horizontalPadding(context),
        ResponsiveUtils.spacing(context, 10),
        ResponsiveUtils.horizontalPadding(context),
        ResponsiveUtils.spacing(context, 12),
      ),
      child: SafeArea(
        top: false,
        child: child,
      ),
    );
  }
}
