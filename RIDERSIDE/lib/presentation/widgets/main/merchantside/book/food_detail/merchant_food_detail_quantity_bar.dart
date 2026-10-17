import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

/// Compact quantity stepper pill, meant to sit beside the add-to-cart button.
class MerchantFoodDetailQuantityBar extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const MerchantFoodDetailQuantityBar({
    super.key,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 6),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EEF8),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.spacing(context, 14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: quantity > 1 ? onDecrease : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 32),
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 17),
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
          _StepButton(icon: Icons.add_rounded, onTap: onIncrease),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: icon == Icons.add_rounded
          ? 'Increase quantity'
          : 'Decrease quantity',
      onPressed: onTap,
      color: const Color(0xFF5F2D82),
      icon: Icon(icon, size: 22),
    );
  }
}
