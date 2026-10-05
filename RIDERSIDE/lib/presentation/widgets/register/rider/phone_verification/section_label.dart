import 'package:flutter/material.dart';
import '../../../../../core/utils/utils.dart';

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
          color: Colors.black87,
        ),
      ),
    );
  }
}
