import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/entities/booking/leseat/food_category.dart';

class CategoryChip extends StatelessWidget {
  final FoodCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = ResponsiveUtils.fontSize(context, 28);
    final fontSize = ResponsiveUtils.fontSize(context, 11);
    final padding = ResponsiveUtils.spacing(context, 7);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ResponsiveUtils.spacing(context, 56),
            height: ResponsiveUtils.spacing(context, 56),
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE8E0F0) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF5F2D82)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: SvgPicture.asset(
              category.iconPath,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 3)),
          Text(
            category.name,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: fontSize,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? const Color(0xFF5F2D82) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
