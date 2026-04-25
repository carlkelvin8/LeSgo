import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class MerchantFoodCategoryChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;

  const MerchantFoodCategoryChip({
    super.key,
    required this.label,
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? const Color(0xFFE6E6E6)
        : const Color(0xFFF0F0F0);

    return Container(
      width: ResponsiveUtils.spacing(context, 74),
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.spacing(context, 10),
        horizontal: ResponsiveUtils.spacing(context, 8),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ResponsiveUtils.spacing(context, 42),
            height: ResponsiveUtils.spacing(context, 42),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: Text(
              icon,
              style: TextStyle(fontSize: ResponsiveUtils.fontSize(context, 22)),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 10),
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
