import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';

class MerchantRatingStarsDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final bool showRatingText;

  const MerchantRatingStarsDisplay({
    super.key,
    required this.rating,
    this.size = 16,
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
            color: (isActive || isHalf)
                ? const Color(0xFFFFA000)
                : const Color(0xFFE0E0E0),
          );
        }),
        if (showRatingText) ...[
          SizedBox(width: ResponsiveUtils.spacing(context, 4)),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ],
    );
  }
}
