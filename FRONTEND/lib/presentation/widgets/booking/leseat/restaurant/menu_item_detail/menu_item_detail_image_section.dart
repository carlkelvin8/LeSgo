import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../domain/entities/booking/leseat/menu_item.dart';

class MenuItemDetailImageSection extends StatelessWidget {
  final MenuItem menuItem;

  const MenuItemDetailImageSection({super.key, required this.menuItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.grey[200]),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          // Background Image
          menuItem.imagePath.toLowerCase().endsWith('.svg')
              ? SvgPicture.asset(
                  menuItem.imagePath,
                  fit: BoxFit.cover,
                  placeholderBuilder: (BuildContext context) => Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(
                        Icons.fastfood,
                        size: ResponsiveUtils.fontSize(context, 80),
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                )
              : Image.asset(
                  menuItem.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(
                          Icons.fastfood,
                          size: ResponsiveUtils.fontSize(context, 80),
                          color: Colors.grey[400],
                        ),
                      ),
                    );
                  },
                ),

          // Gradient Overlay (optional, for better text readability if needed)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
