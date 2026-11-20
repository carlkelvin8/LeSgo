import 'package:flutter/material.dart';
import '../../../../../core/utils/utils.dart';
import '../../../../../core/utils/dark_aware_colors.dart';

class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: ResponsiveUtils.fontSize(context, 16),
          fontWeight: FontWeight.w600,
          color: context.txt(Colors.black87),
        ),
      ),
    );
  }
}
