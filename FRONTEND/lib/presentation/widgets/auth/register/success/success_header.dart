import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';

class SuccessHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const SuccessHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 24),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: ResponsiveUtils.fontSize(context, 14),
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
