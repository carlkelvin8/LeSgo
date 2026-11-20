import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
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
    return Container(
      height: 56,
      color: AppColors.surface(context, const Color(0xFFFEFDFE)),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Vertical padding keeps the pills off the row's edges; they were
        // stretched to the full row height before.
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected =
              selectedCategoryId == category.id ||
              (selectedCategoryId == null && category.id == 'popular');

          return Material(
            color: isSelected
                ? AppColors.accent(context, Color(0xFF5F2D82))
                : AppColors.surface(context, Color(0xFFF5F4F7)),
            shape: StadiumBorder(
              side: isSelected
                  ? BorderSide.none
                  : BorderSide(
                      color: AppColors.border(context, const Color(0xFFECEAF0)),
                    ),
            ),
            child: InkWell(
              onTap: () => onCategorySelected(category.id),
              customBorder: const StadiumBorder(),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (category.id == 'popular')
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: isSelected
                              ? AppColors.onAccent(context)
                              : const Color(0xFFFF6D00),
                        ),
                      ),
                    Text(
                      category.name,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.onAccent(context)
                            : AppColors.foreground(context, Color(0xFF302B36)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
