import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../common/media_image.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/entities/booking/leseat/restaurant.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantCard({ super.key, required this.restaurant, this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderRadius = ResponsiveUtils.spacing(context, 12);
    final imageHeight = ResponsiveUtils.imageHeight(context, 160);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 16)),
        decoration: BoxDecoration(
          color: AppColors.surface(context, Colors.white),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(borderRadius),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: imageHeight,
                    color: AppColors.surface(context, Colors.grey[200]!),
                    child: MediaImage(
                      imagePath: restaurant.imagePath,
                      fit: BoxFit.cover,
                      placeholder: Center(
                        child: Icon(
                          Icons.restaurant,
                          size: ResponsiveUtils.fontSize(context, 48),
                          color: AppColors.foreground(context, Colors.grey[400]!),
                        ),
                      ),
                    ),
                  ),
                ),
                if (restaurant.isNew)
                  Positioned(
                    top: ResponsiveUtils.spacing(context, 12),
                    right: ResponsiveUtils.spacing(context, 12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.spacing(context, 12),
                        vertical: ResponsiveUtils.spacing(context, 6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'NEW',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 10),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Restaurant Details
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground(context, Colors.black87),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Text(
                    restaurant.address,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: AppColors.foreground(context, Colors.grey[600]!),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: ResponsiveUtils.fontSize(context, 16),
                        color: Colors.amber,
                      ),
                      SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                      Text(
                        restaurant.rating.toString(),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground(context, Colors.black87),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                      Text(
                        '(${restaurant.reviewCount}+)',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 12),
                          color: AppColors.foreground(context, Colors.grey[600]!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
