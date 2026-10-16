import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/responsive_utils.dart';

class OffersEmptyState extends StatelessWidget {
  const OffersEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface(context, Colors.grey[100]!),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_offer_outlined,
                color: AppColors.foreground(context, Colors.grey[400]!),
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No offers here yet',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 16),
                fontWeight: FontWeight.w800,
                color: AppColors.foreground(context, Colors.black87),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try another category.',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                color: AppColors.foreground(context, Colors.grey[500]!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
