import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../domain/entities/booking/lesbuy/product.dart';

class StoreProductDetailImageSection extends StatelessWidget {
  final Product product;

  const StoreProductDetailImageSection({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.surface(context, Colors.grey[200]!)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          // Background Image
          product.imagePath.toLowerCase().endsWith('.svg')
              ? SvgPicture.asset(
                  product.imagePath,
                  fit: BoxFit.cover,
                  placeholderBuilder: (BuildContext context) => Container(
                    color: AppColors.surface(context, Colors.grey[300]!),
                    child: Center(
                      child: Icon(
                        Icons.shopping_bag,
                        size: ResponsiveUtils.fontSize(context, 80),
                        color: AppColors.foreground(context, Colors.grey[400]!),
                      ),
                    ),
                  ),
                )
              : Image.asset(
                  product.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.surface(context, Colors.grey[300]!),
                      child: Center(
                        child: Icon(
                          Icons.shopping_bag,
                          size: ResponsiveUtils.fontSize(context, 80),
                          color: AppColors.foreground(context, Colors.grey[400]!),
                        ),
                      ),
                    );
                  },
                ),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
