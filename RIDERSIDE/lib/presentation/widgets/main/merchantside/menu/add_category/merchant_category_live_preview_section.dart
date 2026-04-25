import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class MerchantCategoryLivePreviewSection extends StatelessWidget {
  final String categoryName;
  final String? categoryImagePath;
  final int dishCount;

  const MerchantCategoryLivePreviewSection({
    super.key,
    required this.categoryName,
    this.categoryImagePath,
    this.dishCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Preview',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEAD3F7).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEAD3F7)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                Container(
                  height: ResponsiveUtils.spacing(context, 140),
                  width: double.infinity,
                  color: const Color(0xFFEAD3F7),
                  child: Center(
                    child: categoryImagePath != null
                        ? Image.asset(
                            categoryImagePath!,
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.image,
                            size: ResponsiveUtils.spacing(context, 48),
                            color: const Color(0xFF5F2D82).withValues(alpha: 0.3),
                          ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName.isEmpty ? 'Category Name' : categoryName,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5F2D82),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                      Text(
                        '$dishCount ${dishCount == 1 ? 'dish' : 'dishes'}',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 12),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
