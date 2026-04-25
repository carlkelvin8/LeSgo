import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

class CustomDivider extends StatelessWidget {
  final double? height;
  final double? thickness;
  final double? indent;
  final double? endIndent;
  final Color? color;

  const CustomDivider({
    super.key,
    this.height,
    this.thickness = 1,
    this.indent,
    this.endIndent,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height ?? ResponsiveUtils.spacing(context, 32),
      thickness: thickness,
      indent: indent ?? ResponsiveUtils.spacing(context, 16),
      endIndent: endIndent ?? ResponsiveUtils.spacing(context, 16),
      color: color ?? Colors.grey[300],
    );
  }
}
