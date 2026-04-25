import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/entities/booking/leseat/food_category.dart';
import 'category_chip.dart';

class CategoryListSection extends StatelessWidget {
  final List<FoodCategory> categories;
  final String? selectedCategoryId;
  final Function(String?) onCategorySelected;

  const CategoryListSection({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ResponsiveUtils.spacing(context, 90),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 16),
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategoryId == category.id;

          return Padding(
            padding: EdgeInsets.only(
              right: ResponsiveUtils.spacing(context, 16),
            ),
            child: CategoryChip(
              category: category,
              isSelected: isSelected,
              onTap: () {
                onCategorySelected(isSelected ? null : category.id);
              },
            ),
          );
        },
      ),
    );
  }
}
