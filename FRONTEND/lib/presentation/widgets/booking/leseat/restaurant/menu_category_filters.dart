import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../domain/entities/booking/leseat/food_category.dart';

class MenuCategoryFilters extends StatelessWidget {
  final List<FoodCategory> categories;
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;

  const MenuCategoryFilters({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.horizontalPadding(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: categories.map((category) {
          final isSelected = selectedCategoryId == category.id ||
              (selectedCategoryId == null && category.id == 'popular');

          return Padding(
            padding: EdgeInsets.only(
              right: ResponsiveUtils.spacing(context, 8),
            ),
            child: FilterChip(
              label: Text(
                category.name,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onCategorySelected(category.id),
              backgroundColor: Colors.grey[100],
              selectedColor: const Color(0xFF5F2D82),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF5F2D82) : Colors.transparent,
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.spacing(context, 4),
                vertical: ResponsiveUtils.spacing(context, 4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
