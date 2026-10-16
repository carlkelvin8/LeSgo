import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../domain/entities/booking/lesbuy/store.dart';

class StoreDetailHeader extends StatelessWidget {
  final Store store;
  final double height;

  const StoreDetailHeader({
    super.key,
    required this.store,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(color: AppColors.surface(context, Colors.grey[300]!)),
          child: Image.asset(
            store.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.surface(context, Colors.grey[300]!),
                child: Icon(
                  Icons.store,
                  size: ResponsiveUtils.fontSize(context, 64),
                  color: AppColors.foreground(context, Colors.grey[400]!),
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
            height: height * 0.6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
