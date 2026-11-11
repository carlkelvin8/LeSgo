import 'package:flutter/material.dart';
import '../../../../../provider/main/merchantside/merchant_food_detail_provider.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../common/menu_image_widget.dart';
import '../../../../../../core/utils/dark_aware_colors.dart';

class MerchantFoodDetailContent extends StatelessWidget {
  final String foodName;
  final String? foodImage;
  final String displayPrice;
  final String description;
  final List<MerchantFoodSizeOption> sizes;
  final MerchantFoodSizeOption selectedSize;
  final ValueChanged<MerchantFoodSizeOption> onSelectSize;
  final List<MerchantFoodSizeOption> flavors;
  final MerchantFoodSizeOption? selectedFlavor;
  final ValueChanged<MerchantFoodSizeOption>? onSelectFlavor;
  final List<MerchantFoodSizeOption> addons;
  final List<MerchantFoodSizeOption> selectedAddons;
  final ValueChanged<MerchantFoodSizeOption>? onToggleAddon;

  const MerchantFoodDetailContent({
    super.key,
    required this.foodName,
    required this.foodImage,
    required this.displayPrice,
    required this.description,
    required this.sizes,
    required this.selectedSize,
    required this.onSelectSize,
    this.flavors = const [],
    this.selectedFlavor,
    this.onSelectFlavor,
    this.addons = const [],
    this.selectedAddons = const [],
    this.onToggleAddon,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: ResponsiveUtils.spacing(context, 12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: ResponsiveUtils.imageHeight(context, 200),
              decoration: BoxDecoration(
                color: context.surf(const Color(0xFFF2F2F2)),
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.spacing(context, 16),
                ),
              ),
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              child: foodImage != null && foodImage!.trim().isNotEmpty
                  ? MenuImageWidget(
                      source: foodImage,
                      fit: BoxFit.cover,
                      placeholder: Icon(
                        Icons.image_not_supported,
                        size: 60,
                        color: context.sub(Colors.grey.shade400),
                      ),
                    )
                  : Icon(
                      Icons.image_not_supported,
                      size: 60,
                      color: context.sub(Colors.grey.shade400),
                    ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            Text(
              foodName,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 22),
                fontWeight: FontWeight.w800,
                color: context.txt(Colors.black),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              displayPrice,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 18),
                fontWeight: FontWeight.w700,
                color: context.acc(const Color(0xFF5F2D82)),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Text(
              description,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                fontWeight: FontWeight.w400,
                color: context.txt(Colors.grey.shade600),
                height: 1.5,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 24)),
            Text(
              'Size:',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 16),
                fontWeight: FontWeight.w700,
                color: context.txt(Colors.black),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Wrap(
              spacing: ResponsiveUtils.spacing(context, 8),
              children: sizes.map((size) {
                final isSelected = selectedSize == size;
                return GestureDetector(
                  onTap: () => onSelectSize(size),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.spacing(context, 16),
                      vertical: ResponsiveUtils.spacing(context, 10),
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF5F2D82) : Colors.white,
                      border: Border.all(
                        color: const Color(0xFF5F2D82),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.spacing(context, 8),
                      ),
                    ),
                    child: Text(
                      size.price > 0
                          ? '${size.label}  +\u20B1${size.price.toStringAsFixed(0)}'
                          : size.label,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.white : const Color(0xFF5F2D82),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (flavors.isNotEmpty) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 24)),
              _OptionTitle(label: 'Flavor:'),
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              _OptionChips(
                choices: flavors,
                isSelected: (choice) => selectedFlavor == choice,
                onTap: (choice) => onSelectFlavor?.call(choice),
              ),
            ],
            if (addons.isNotEmpty) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 24)),
              _OptionTitle(label: 'Add-ons:'),
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              _OptionChips(
                choices: addons,
                isSelected: selectedAddons.contains,
                onTap: (choice) => onToggleAddon?.call(choice),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionTitle extends StatelessWidget {
  const _OptionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, 16),
        fontWeight: FontWeight.w700,
        color: context.txt(Colors.black),
      ),
    );
  }
}

class _OptionChips extends StatelessWidget {
  const _OptionChips({
    required this.choices,
    required this.isSelected,
    required this.onTap,
  });

  final List<MerchantFoodSizeOption> choices;
  final bool Function(MerchantFoodSizeOption) isSelected;
  final ValueChanged<MerchantFoodSizeOption> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ResponsiveUtils.spacing(context, 8),
      runSpacing: ResponsiveUtils.spacing(context, 8),
      children: choices.map((choice) {
        final selected = isSelected(choice);
        final price = choice.price > 0 ? '  +\u20B1${choice.price.toStringAsFixed(0)}' : '';
        return GestureDetector(
          onTap: () => onTap(choice),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.spacing(context, 16),
              vertical: ResponsiveUtils.spacing(context, 10),
            ),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF5F2D82) : Colors.white,
              border: Border.all(color: const Color(0xFF5F2D82), width: 2),
              borderRadius: BorderRadius.circular(ResponsiveUtils.spacing(context, 8)),
            ),
            child: Text(
              '${choice.label}$price',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF5F2D82),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
