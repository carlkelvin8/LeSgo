import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';

class RememberMeCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String text;

  const RememberMeCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.text = 'Remember for 30 days',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: ResponsiveUtils.fontSize(context, 20),
          width: ResponsiveUtils.fontSize(context, 20),
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            activeColor: const Color(0xFF6B4EFF),
          ),
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 8)),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
