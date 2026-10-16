import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../common/media_image.dart';
import '../../../../../domain/entities/booking/leseat/restaurant.dart';

class RestaurantDetailHeader extends StatelessWidget {
  final Restaurant restaurant;
  final String? imagePath;
  final double? height;

  const RestaurantDetailHeader({
    super.key,
    required this.restaurant,
    this.imagePath,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final headerHeight = height ?? ResponsiveUtils.imageHeight(context, 200);

    return Container(
      width: double.infinity,
      height: headerHeight,
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.grey[100]!),
      ),
      child: MediaImage(
        imagePath: imagePath ?? restaurant.imagePath,
        fit: BoxFit.cover,
        placeholder: Container(
          color: AppColors.surface(context, Colors.grey[100]!),
          child: Center(
            child: Icon(
              Icons.restaurant_menu,
              size: 48,
              color: AppColors.foreground(context, Colors.grey[300]!),
            ),
          ),
        ),
      ),
    );
  }
}
