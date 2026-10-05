import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/entities/booking/lesbuy/store.dart';

class StoreCard extends StatelessWidget {
  final Store store;
  final VoidCallback? onTap;

  const StoreCard({
    super.key,
    required this.store,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = ResponsiveUtils.spacing(context, 12);
    final imageHeight = ResponsiveUtils.imageHeight(context, 160);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          bottom: ResponsiveUtils.spacing(context, 16),
        ),
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
            // Store Image
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
                    child: Center(
                      child: Icon(
                        _getStoreIcon(store.categories),
                        size: ResponsiveUtils.fontSize(context, 64),
                        color: AppColors.accent(context, Color(0xFF5F2D82)).withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                if (store.isNew)
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

            // Store Details
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground(context, Colors.black87),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Text(
                    store.address,
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
                        store.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 13),
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground(context, Colors.black87),
                        ),
                      ),
                      Text(
                        ' (${store.reviewCount}+)',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 12),
                          color: AppColors.foreground(context, Colors.grey[500]!),
                        ),
                      ),
                      const Spacer(),
                      if (store.deliveryTime != null) ...[
                        Icon(
                          Icons.access_time,
                          size: ResponsiveUtils.fontSize(context, 14),
                          color: AppColors.foreground(context, Colors.grey[500]!),
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                        Text(
                          store.deliveryTime!,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                            color: AppColors.foreground(context, Colors.grey[600]!),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (store.storeType != null) ...[
                    SizedBox(height: ResponsiveUtils.spacing(context, 6)),
                    Text(
                      store.storeType!,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 11),
                        color: AppColors.foreground(context, Colors.grey[500]!),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStoreIcon(List<String> categories) {
    if (categories.contains('pharmacy') || categories.contains('health')) {
      return Icons.local_pharmacy;
    }
    if (categories.contains('books') || categories.contains('school_supplies')) {
      return Icons.menu_book;
    }
    if (categories.contains('hardware') || categories.contains('tools')) {
      return Icons.hardware;
    }
    if (categories.contains('beauty') || categories.contains('personal_care')) {
      return Icons.spa;
    }
    if (categories.contains('pets') || categories.contains('pet_food')) {
      return Icons.pets;
    }
    return Icons.store;
  }
}
