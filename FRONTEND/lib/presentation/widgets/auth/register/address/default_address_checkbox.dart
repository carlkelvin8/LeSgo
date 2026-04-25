import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';

class DefaultAddressCheckbox extends StatelessWidget {
  final bool isDefault;
  final Function(bool?) onChanged;

  const DefaultAddressCheckbox({
    super.key,
    required this.isDefault,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: ResponsiveUtils.fontSize(context, 20),
          height: ResponsiveUtils.fontSize(context, 20),
          child: Checkbox(
            value: isDefault,
            onChanged: onChanged,
            activeColor: const Color(0xFF5F2D82),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 8)),
        Text(
          'Set as default address?',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
