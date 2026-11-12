import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../core/utils/screen_auto_refresh.dart';
import '../../../../../mixins/auto_refresh_mixin.dart';
import '../../../../../provider/main/merchantside/merchant_menu_provider.dart';
import '../../../../../../core/utils/dark_aware_colors.dart';
import '../../../../../../core/utils/app_localization.dart';

class MerchantItemCategorySection extends ConsumerStatefulWidget {
  final String selectedCategory;
  final ValueChanged<String?> onChanged;

  const MerchantItemCategorySection({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  ConsumerState<MerchantItemCategorySection> createState() =>
      _MerchantItemCategorySectionState();
}

class _MerchantItemCategorySectionState
    extends ConsumerState<MerchantItemCategorySection>
    with WidgetsBindingObserver, AutoRefreshMixin {
  @override
  Duration get autoRefreshInterval => kScreenAutoRefreshInterval;

  @override
  void onAutoRefresh() {
    ref.invalidate(merchantMenuProvider);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(merchantMenuProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(merchantMenuProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Category'),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            fontWeight: FontWeight.w700,
            color: context.acc(const Color(0xFF5F2D82)),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.spacing(context, 12),
          ),
          decoration: BoxDecoration(
            color: context.surf(Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.brd(Colors.grey.shade300)),
          ),
          child: menuAsync.when(
            loading: () => DropdownButton<String>(
              isExpanded: true,
              value: null,
              onChanged: null,
              underline: const SizedBox(),
              hint: Text(
                context.tr('Loading categories...'),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  color: context.sub(Colors.grey.shade600),
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
                context.tr('Error loading categories'),
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
                    context.tr('No categories available'),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      color: context.sub(Colors.grey.shade600),
                    ),
                  ),
                  items: const [],
                );
              }

              final categoryNames =
                  menu.categories.map((cat) => cat.name).toSet().toList();
              final hasSelected = categoryNames.contains(widget.selectedCategory);

              return DropdownButton<String>(
                isExpanded: true,
                value: hasSelected ? widget.selectedCategory : null,
                onChanged: widget.onChanged,
                underline: const SizedBox(),
                hint: Text(
                  context.tr('Select a category'),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    color: context.sub(Colors.grey.shade600),
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
                  color: context.txt(Colors.black),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
