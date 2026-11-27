import 'package:lesgo/presentation/widgets/booking/common/order_design.dart';
import 'package:flutter/material.dart';

class LesrideChangeButton extends StatelessWidget {
  const LesrideChangeButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: OrderDesign.accent(context),
        minimumSize: const Size(48, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: Text(
        'Change',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: OrderDesign.accent(context),
        ),
      ),
    );
  }
}
