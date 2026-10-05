import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../domain/entities/booking/leseat/restaurant.dart';

class RestaurantInfoCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onViewReviews;

  const RestaurantInfoCard({
    super.key,
    required this.restaurant,
    this.onViewReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant Name
          Text(
            restaurant.name,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 24),
              fontWeight: FontWeight.w700,
              color: AppColors.foreground(context, Colors.black87),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),

          // Rating Badge
          GestureDetector(
            onTap: onViewReviews,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.spacing(context, 12),
                vertical: ResponsiveUtils.spacing(context, 6),
              ),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${restaurant.rating}',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                  Icon(
                    Icons.star,
                    size: ResponsiveUtils.fontSize(context, 14),
                    color: Colors.white,
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                  Text(
                    '${restaurant.reviewCount}+ ratings',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: Colors.white,
                    ),
                  ),
                  if (onViewReviews != null) ...[
                    SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                    Icon(
                      Icons.chevron_right,
                      size: ResponsiveUtils.fontSize(context, 16),
                      color: Colors.white,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),

          // Cuisine
          if (restaurant.cuisine != null)
            Text(
              restaurant.cuisine!,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: AppColors.foreground(context, Colors.grey[700]!),
              ),
            ),

          SizedBox(height: ResponsiveUtils.spacing(context, 12)),

          // Opening Hours & Location
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (restaurant.openingHours != null)
                _DeliveryDetail(
                  icon: Icons.access_time,
                  text: restaurant.openingHours!,
                  context: context,
                ),
              if (restaurant.openingHours != null)
                SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              _DeliveryDetail(
                icon: Icons.location_on,
                text: restaurant.address,
                context: context,
                expanded: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryDetail extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool expanded;

  const _DeliveryDetail({
    required this.icon,
    required this.text,
    required BuildContext context,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: ResponsiveUtils.fontSize(context, 16),
          color: AppColors.accent(context, Color(0xFF5F2D82)),
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 4)),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 12),
              color: AppColors.foreground(context, Colors.grey[700]!),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

