import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

class DrawerDivider extends StatelessWidget {
  const DrawerDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 24),
      ),
      child: Container(
        height: 1,
        color: Colors.white.withValues(alpha: 0.2),
      ),
    );
  }
}
