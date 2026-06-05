import 'package:flutter/material.dart';
import '../../../../../provider/main/merchantside/merchant_food_detail_provider.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../common/menu_image_widget.dart';

class MerchantFoodDetailContent extends StatelessWidget {
  final String foodName;
  final String? foodImage;
  final String displayPrice;
  final String description;
  final List<MerchantFoodSizeOption> sizes;
  final MerchantFoodSizeOption selectedSize;
  final ValueChanged<MerchantFoodSizeOption> onSelectSize;

  const MerchantFoodDetailContent({
    super.key,
    required this.foodName,
    required this.foodImage,
    required this.displayPrice,
    required this.description,
    required this.sizes,
    required this.selectedSize,
    required this.onSelectSize,
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
                color: const Color(0xFFF2F2F2),
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
                        color: Colors.grey.shade400,
                      ),
                    )
                  : Icon(
                      Icons.image_not_supported,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            Text(
              foodName,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 22),
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              displayPrice,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 18),
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5F2D82),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Text(
              description,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
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
                color: Colors.black,
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
                      size.label,
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
          ],
        ),
      ),
    );
  }
}
