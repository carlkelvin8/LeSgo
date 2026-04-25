import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

/// Reusable star rating widget
/// Can be used for both display and input
class RatingStars extends StatelessWidget {
  final int rating;
  final Function(int)? onRatingChanged;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool enabled;

  const RatingStars({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.size = 32,
    this.activeColor = const Color(0xFFFFA000),
    this.inactiveColor = const Color(0xFFE0E0E0),
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isActive = index < rating;
        return GestureDetector(
          onTap: enabled && onRatingChanged != null
              ? () => onRatingChanged!(index + 1)
              : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.spacing(context, 4),
            ),
            child: Icon(
              isActive ? Icons.star : Icons.star_border,
              size: size,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        );
      }),
    );
  }
}

/// Display-only rating stars (smaller, for lists)
class RatingStarsDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool showRatingText;

  const RatingStarsDisplay({
    super.key,
    required this.rating,
    this.size = 16,
    this.activeColor = const Color(0xFFFFA000),
    this.inactiveColor = const Color(0xFFE0E0E0),
    this.showRatingText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final isActive = index < rating.floor();
          final isHalf = !isActive && index < rating.ceil() && rating % 1 != 0;

          return Icon(
            isHalf ? Icons.star_half : (isActive ? Icons.star : Icons.star_border),
            size: size,
            color: (isActive || isHalf) ? activeColor : inactiveColor,
          );
        }),
        if (showRatingText) ...[
          SizedBox(width: ResponsiveUtils.spacing(context, 4)),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ],
    );
  }
}
