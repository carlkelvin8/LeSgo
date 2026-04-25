import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

/// Reusable spacer for consistent spacing between form sections
class SectionSpacer extends StatelessWidget {
  final int units; // Default: 16 spacing units

  const SectionSpacer({
    super.key,
    this.units = 16,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: ResponsiveUtils.spacing(context, units.toDouble()));
  }
}
