import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../common/media_image.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../../domain/entities/booking/leseat/menu_item.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback? onTap;

  const MenuItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardPadding = ResponsiveUtils.cardPadding(context);
    final imageSize = ResponsiveUtils.cardImageSize(context, 120);
    final maxLines = ResponsiveUtils.cardDescriptionMaxLines(context);

    return InkWell(
      onTap:
          onTap ??
          () {
            AppRouter.push(
              context,
              BookingRoutes.leseatMenuItemDetail,
              arguments: item,
            );
          },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(
          bottom: 0,
        ), // Parent handles padding usually, but StoreProductList had explicit margin. MenuItemCard relies on parent? Parent uses Padding.
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image (Left) - Matching StoreProductList
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: imageSize,
                height: imageSize,
                color: Colors.grey[100],
                child: MediaImage(
                  imagePath: item.imagePath,
                  fit: BoxFit.cover,
                  width: imageSize,
                  height: imageSize,
                  placeholder: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),

            // Text Content (Right)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Item Name
                  Text(
                    item.name,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),

                  // Description
                  Text(
                    item.description,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: Colors.grey[600],
                    ),
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),

                  // Price
                  Text(
                    '₱${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5F2D82),
                    ),
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
