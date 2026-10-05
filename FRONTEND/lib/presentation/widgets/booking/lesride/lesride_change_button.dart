import 'package:flutter/material.dart';
import 'package:lesgo/core/theme/app_colors.dart';

class LesrideChangeButton extends StatelessWidget {
  const LesrideChangeButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        'Change',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.accent(context, const Color(0xFF7C3AED)),
        ),
      ),
    );
  }
}
