import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../domain/entities/booking/leseat/menu_item.dart';

class MenuItemDetailInfoSection extends StatelessWidget {
  final MenuItem menuItem;
  final double adjustedPrice;

  const MenuItemDetailInfoSection({
    super.key,
    required this.menuItem,
    required this.adjustedPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          menuItem.name,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 24),
            fontWeight: FontWeight.w700,
            color: AppColors.foreground(context, Colors.black87),
            height: 1.2,
          ),
        ),

        SizedBox(height: ResponsiveUtils.spacing(context, 12)),

        // Price and Delivery Time
        Row(
          children: [
            // Price
            Text(
              '₱${adjustedPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 20),
                fontWeight: FontWeight.w700,
                color: AppColors.accent(context, Color(0xFF5F2D82)),
              ),
            ),

            SizedBox(width: ResponsiveUtils.spacing(context, 8)),

            // Dot separator
            Container(
              width: 4,
              height: 4,
              decoration:  BoxDecoration(
                color: AppColors.surface(context, Colors.grey),
                shape: BoxShape.circle,
              ),
            ),

            SizedBox(width: ResponsiveUtils.spacing(context, 8)),

            // Delivery Time
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: ResponsiveUtils.fontSize(context, 16),
                  color: AppColors.foreground(context, Colors.grey[600]!),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                Text(
                  '20-30 min',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    color: AppColors.foreground(context, Colors.grey[600]!),
                  ),
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        // Description
        Text(
          menuItem.description,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            color: AppColors.foreground(context, Colors.grey[700]!),
            height: 1.5,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
