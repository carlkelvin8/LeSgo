import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/responsive_utils.dart';

class OffersFilterBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const OffersFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ResponsiveUtils.spacing(context, 44),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 20),
        ),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => onCategorySelected(category),
            showCheckmark: false,
            labelStyle: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 12),
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.foreground(context, Colors.grey[700]!),
            ),
            selectedColor: const Color(0xFF5F2D82),
            backgroundColor: AppColors.surface(context, Colors.grey[100]!),
            side: BorderSide(
              color: isSelected ? AppColors.accent(context, Color(0xFF5F2D82)) : AppColors.foreground(context, Colors.grey[200]!),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          );
        },
      ),
    );
  }
}
