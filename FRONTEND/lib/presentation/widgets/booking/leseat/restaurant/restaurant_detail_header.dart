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
    final headerHeight = height ?? ResponsiveUtils.imageHeight(context, 240);

    return Stack(
      children: [
        // Background Image
        Container(
          width: double.infinity,
          height: headerHeight,
          decoration: BoxDecoration(color: Colors.grey[300]),
          child: MediaImage(
            imagePath: imagePath ?? restaurant.imagePath,
            fit: BoxFit.cover,
            placeholder: Container(
              color: Colors.grey[300],
              child: Center(
                child: Icon(
                  Icons.restaurant,
                  size: ResponsiveUtils.fontSize(context, 64),
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
        ),

        // Gradient Overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: headerHeight * 0.6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
