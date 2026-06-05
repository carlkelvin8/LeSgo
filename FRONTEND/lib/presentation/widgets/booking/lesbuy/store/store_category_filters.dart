import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class StoreCategoryFilters extends StatelessWidget {
  final List<String> categories;
  final Map<String, String>? categoryLabels;
  final String? selectedCategoryId;
  final Function(String) onCategorySelected;

  const StoreCategoryFilters({
    super.key,
    required this.categories,
    this.categoryLabels,
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
          final isSelected = category == selectedCategoryId;
          final displayName = categoryLabels?[category] ??
              (category == 'popular'
                  ? 'Popular'
                  : category.split('_').map((word) {
                      if (word.isEmpty) return word;
                      return word[0].toUpperCase() + word.substring(1);
                    }).join(' '));
                  
          return Padding(
            padding: EdgeInsets.only(
              right: ResponsiveUtils.spacing(context, 8),
            ),
            child: FilterChip(
              label: Text(
                displayName,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onCategorySelected(category),
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
