import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';

class CartScreenHeader extends StatelessWidget {
  final VoidCallback onBack;

  const CartScreenHeader({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: ResponsiveUtils.spacing(context, 12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Icon(
              Icons.arrow_back,
              size: ResponsiveUtils.imageHeight(context, 24),
              color: const Color(0xFF202020),
            ),
          ),
          const Spacer(),
          Text(
            'Checkout',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w800,
              color: const Color(0xFF202020),
            ),
          ),
          const Spacer(),
          SizedBox(width: ResponsiveUtils.spacing(context, 32)),
        ],
      ),
    );
  }
}
