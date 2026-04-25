import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../domain/entities/booking/leseat/restaurant.dart';

class RestaurantDetailHeader extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetailHeader({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final headerHeight = ResponsiveUtils.imageHeight(context, 280);

    return Stack(
      children: [
        // Background Image
        Container(
          width: double.infinity,
          height: headerHeight,
          decoration: BoxDecoration(color: Colors.grey[300]),
          child: restaurant.imagePath.toLowerCase().endsWith('.svg')
              ? SvgPicture.asset(
                  restaurant.imagePath,
                  fit: BoxFit.cover,
                  placeholderBuilder: (BuildContext context) => Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(
                        Icons.restaurant,
                        size: ResponsiveUtils.fontSize(context, 64),
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                )
              : Image.asset(
                  restaurant.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(
                          Icons.restaurant,
                          size: ResponsiveUtils.fontSize(context, 64),
                          color: Colors.grey[400],
                        ),
                      ),
                    );
                  },
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
