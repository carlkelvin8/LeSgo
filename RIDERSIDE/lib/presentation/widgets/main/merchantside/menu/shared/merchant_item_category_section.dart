import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class MerchantItemCategorySection extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String?> onChanged;
  final List<String> categories;

  const MerchantItemCategorySection({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
    this.categories = const ['Pizza', 'Pasta', 'Salad', 'Beverage', 'Dessert'],
  });

  @override
  Widget build(BuildContext context) {
    // Keep category list unique and include current value if it came from existing data.
    final uniqueCategories = <String>{...categories};
    if (selectedCategory.trim().isNotEmpty) {
      uniqueCategories.add(selectedCategory.trim());
    }
    final categoryItems = uniqueCategories.toList();
    final hasSelected = categoryItems.contains(selectedCategory);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.spacing(context, 12),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            value: hasSelected ? selectedCategory : null,
            onChanged: onChanged,
            underline: const SizedBox(),
            hint: Text(
              'Select a category',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: Colors.grey.shade600,
              ),
            ),
            items: categoryItems.map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(
                  category,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                  ),
                ),
              );
            }).toList(),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
