import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class StoreProductQuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const StoreProductQuantitySelector({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = ResponsiveUtils.buttonHeight(context);

    return Container(
      height: buttonHeight,
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        border: Border.all(color: AppColors.accent(context, Color(0xFF5F2D82)), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Decrement Button
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: quantity > 1 ? onDecrement : null,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.remove,
                    size: 20,
                    color: quantity > 1
                        ? AppColors.accent(context, Color(0xFF5F2D82))
                        : AppColors.foreground(context, Colors.grey[400]!),
                  ),
                ),
              ),
            ),
          ),

          // Quantity Display
          Container(
            width: buttonHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: AppColors.foreground(context, Colors.grey[200]!), width: 1),
              ),
            ),
            child: Text(
              '$quantity',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 16),
                fontWeight: FontWeight.w600,
                color: AppColors.foreground(context, Colors.black87),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Increment Button
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onIncrement,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.add,
                    size: 20,
                    color: Color(0xFF5F2D82),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
