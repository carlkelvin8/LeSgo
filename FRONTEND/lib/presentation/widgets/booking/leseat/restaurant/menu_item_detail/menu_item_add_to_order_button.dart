import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class MenuItemAddToOrderButton extends StatelessWidget {
  final double totalPrice;
  final VoidCallback onPressed;

  const MenuItemAddToOrderButton({
    super.key,
    required this.totalPrice,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ResponsiveUtils.buttonHeight(context),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5F2D82), Color(0xFF6B4EFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent(context, Color(0xFF5F2D82)).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              'Add to Order',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 16),
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
