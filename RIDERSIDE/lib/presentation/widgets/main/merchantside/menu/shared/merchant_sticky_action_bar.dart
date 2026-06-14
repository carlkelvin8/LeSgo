import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

/// Shared bottom action bar padding for merchant form screens.
class MerchantStickyActionBar extends StatelessWidget {
  final Widget child;

  const MerchantStickyActionBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
