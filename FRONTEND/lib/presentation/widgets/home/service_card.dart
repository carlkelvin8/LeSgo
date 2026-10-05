import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ServiceCard extends StatelessWidget {
  final String? svgPath;
  final IconData? icon;
  final String title;
  final String description;
  final Color gradientStart;
  final Color gradientEnd;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    this.svgPath,
    this.icon,
    required this.title,
    required this.description,
    required this.gradientStart,
    required this.gradientEnd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSvg = svgPath != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: hasSvg ? AppColors.surface(context, Colors.white) : null,
          gradient: hasSvg ? null : LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
              boxShadow: [
            BoxShadow(
              color: hasSvg 
                  ? Colors.black.withValues(alpha: 0.1)
                  : gradientEnd.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon or SVG
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surface(context, Colors.white),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: svgPath != null
                    ? SvgPicture.asset(
                        svgPath!,
                        fit: BoxFit.contain,
                      )
                    : Icon(
                        icon ?? Icons.star,
                        size: 40,
                        color: gradientStart,
                      ),
              ),
              
              // Text content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: hasSvg ? AppColors.foreground(context, Colors.black87) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasSvg 
                          ? AppColors.foreground(context, Colors.grey[600]!)
                          : Colors.white.withValues(alpha: 0.9),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
