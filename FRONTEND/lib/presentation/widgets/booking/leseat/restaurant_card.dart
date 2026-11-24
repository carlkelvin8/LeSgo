import 'package:lesgo/core/theme/app_colors.dart';
import 'package:lesgo/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import '../../common/media_image.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/entities/booking/leseat/restaurant.dart';

/// Compact horizontal restaurant row: square photo, name, cuisine/address and
/// a rating chip. Roughly four fit on a screen instead of one.
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantCard({super.key, required this.restaurant, this.onTap});

  @override
  Widget build(BuildContext context) {
    final image = ResponsiveUtils.imageHeight(context, 96).clamp(88.0, 120.0);

    return Semantics(
      button: true,
      label:
          '${restaurant.name}, rated ${restaurant.rating}, ${restaurant.reviewCount} reviews',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpace.md),
          padding: const EdgeInsets.all(AppSpace.sm),
          decoration: AppCard.decoration(context, radius: AppRadius.lg),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: image,
                  height: image,
                  child: Container(
                    color: AppColors.surface(context, Colors.grey[200]!),
                    child: MediaImage(
                      imagePath: restaurant.imagePath,
                      fit: BoxFit.cover,
                      placeholder: Center(
                        child: Icon(
                          Icons.restaurant,
                          size: 36,
                          color: AppColors.foreground(
                            context,
                            Colors.grey[400]!,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 16),
                              fontWeight: FontWeight.w700,
                              color: AppColors.foreground(
                                context,
                                Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        if (restaurant.isNew) ...[
                          const SizedBox(width: AppSpace.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5484D),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      restaurant.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        height: 1.25,
                        color: AppColors.foreground(context, Colors.grey[600]!),
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Color(0xFFF5A623),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          restaurant.rating.toString(),
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 13),
                            fontWeight: FontWeight.w700,
                            color: AppColors.foreground(
                              context,
                              Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${restaurant.reviewCount}+)',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                            color: AppColors.foreground(
                              context,
                              Colors.grey[600]!,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.foreground(context, Colors.grey[400]!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
