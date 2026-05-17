import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../provider/main/merchantside/merchant_menu_provider.dart';

class MerchantItemCategorySection extends ConsumerWidget {
  final String selectedCategory;
  final ValueChanged<String?> onChanged;

  const MerchantItemCategorySection({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(merchantMenuProvider);

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
          child: menuAsync.when(
            loading: () => DropdownButton<String>(
              isExpanded: true,
              value: null,
              onChanged: null,
              underline: const SizedBox(),
              hint: Text(
                'Loading categories...',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  color: Colors.grey.shade600,
                ),
              ),
              items: const [],
            ),
            error: (error, stack) => DropdownButton<String>(
              isExpanded: true,
              value: null,
              onChanged: null,
              underline: const SizedBox(),
              hint: Text(
                'Error loading categories',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  color: Colors.red,
                ),
              ),
              items: const [],
            ),
            data: (menu) {
              if (menu == null || menu.categories.isEmpty) {
                return DropdownButton<String>(
                  isExpanded: true,
                  value: null,
                  onChanged: null,
                  underline: const SizedBox(),
                  hint: Text(
                    'No categories available',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      color: Colors.grey.shade600,
                    ),
                  ),
                  items: const [],
                );
              }

              final categoryNames = menu.categories.map((cat) => cat.name).toSet().toList();
              final hasSelected = categoryNames.contains(selectedCategory);

              return DropdownButton<String>(
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
                items: categoryNames.map((category) {
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
              );
            },
          ),
        ),
      ],
    );
  }
}
