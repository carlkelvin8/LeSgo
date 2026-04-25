import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

class SectionContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const SectionContainer({
    super.key,
    required this.child,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final defaultMargin = EdgeInsets.symmetric(
      horizontal: ResponsiveUtils.spacing(context, 16.0),
    );
    final defaultPadding = EdgeInsets.all(ResponsiveUtils.spacing(context, 16));
    final borderRadius = ResponsiveUtils.spacing(context, 12);
    
    return Container(
      margin: margin ?? defaultMargin,
      padding: padding ?? defaultPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
