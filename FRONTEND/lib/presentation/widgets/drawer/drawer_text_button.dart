import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

class DrawerTextButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const DrawerTextButton({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 24),
          vertical: ResponsiveUtils.spacing(context, 12),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'TT Fors',
            color: Colors.white,
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
