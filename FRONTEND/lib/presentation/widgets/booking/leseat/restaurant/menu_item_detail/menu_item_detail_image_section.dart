import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../common/media_image.dart';
import '../../../../../../domain/entities/booking/leseat/menu_item.dart';

class MenuItemDetailImageSection extends StatelessWidget {
  final MenuItem menuItem;

  const MenuItemDetailImageSection({super.key, required this.menuItem});

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
          MediaImage(
            imagePath: menuItem.imagePath,
            fit: BoxFit.cover,
            placeholder: Container(
              color: AppColors.surface(context, Colors.grey[300]!),
              child: Center(
                child: Icon(
                  Icons.fastfood,
                  size: ResponsiveUtils.fontSize(context, 80),
                  color: AppColors.foreground(context, Colors.grey[400]!),
                ),
              ),
            ),
          ),

          // Gradient Overlay (optional, for better text readability if needed)
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
