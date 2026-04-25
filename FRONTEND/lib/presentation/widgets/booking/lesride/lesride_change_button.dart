import 'package:flutter/material.dart';

class LesrideChangeButton extends StatelessWidget {
  const LesrideChangeButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: const Text(
        'Change',
        style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF7C3AED)),
      ),
    );
  }
}
