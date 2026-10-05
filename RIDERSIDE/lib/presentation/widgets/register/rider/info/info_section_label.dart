import 'package:flutter/material.dart';
import '../../../../../core/utils/utils.dart';

class InfoSectionLabel extends StatelessWidget {
  final String label;

  const InfoSectionLabel({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, 14),
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}
