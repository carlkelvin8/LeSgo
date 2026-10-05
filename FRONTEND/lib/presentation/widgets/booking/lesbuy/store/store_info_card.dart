import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../domain/entities/booking/lesbuy/store.dart';

class StoreInfoCard extends StatelessWidget {
  final Store store;

  const StoreInfoCard({super.key, required this.store});

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
          // Store Name
          Text(
            store.name,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 22),
              fontWeight: FontWeight.w700,
              color: AppColors.foreground(context, Colors.black87),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),

          // Rating Badge (Matched to LesEat)
          Container(
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
                  '${store.rating}',
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
                  '(${store.reviewCount} user ratings)',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),

          // Store Type
          if (store.storeType != null)
            Text(
              store.storeType!,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: AppColors.foreground(context, Colors.grey[700]!),
              ),
            ),

          SizedBox(height: ResponsiveUtils.spacing(context, 12)),

          // Opening Hours & Location (Matched to LesEat)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (store.openingHours != null)
                _DeliveryDetail(
                  icon: Icons.access_time,
                  text: store.openingHours!,
                  context: context,
                ),
              if (store.openingHours != null)
                SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              _DeliveryDetail(
                icon: Icons.location_on,
                text: store.address,
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
  final BuildContext context;

  const _DeliveryDetail({
    required this.icon,
    required this.text,
    required this.context,
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
