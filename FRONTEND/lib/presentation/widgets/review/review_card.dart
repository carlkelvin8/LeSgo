import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../data/data_source/dto/review/review_dto.dart';
import 'rating_stars.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Reusable review card widget
/// Displays a single review with user info, rating, and comment
class ReviewCard extends StatelessWidget {
  final ReviewDto review;
  final VoidCallback? onHelpful;

  const ReviewCard({
    super.key,
    required this.review,
    this.onHelpful,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Row
          Row(
            children: [
              // User Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF5F2D82).withValues(alpha: 0.1),
                backgroundImage: review.userPhoto != null
                    ? NetworkImage(review.userPhoto!)
                    : null,
                child: review.userPhoto == null
                    ? Text(
                        _getInitials(review.userName ?? 'User'),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5F2D82),
                        ),
                      )
                    : null,
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),

              // User Name and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? 'Anonymous',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                    Text(
                      _formatDate(review.createdAt),
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Rating Stars
              RatingStarsDisplay(
                rating: review.rating.toDouble(),
                size: 16,
              ),
            ],
          ),

          // Comment
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            Text(
              review.comment!,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],

          // Helpful Button
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Row(
            children: [
              InkWell(
                onTap: onHelpful,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.spacing(context, 12),
                    vertical: ResponsiveUtils.spacing(context, 6),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_up_outlined,
                        size: 14,
                        color: Colors.grey.shade700,
                      ),
                      SizedBox(width: ResponsiveUtils.spacing(context, 6)),
                      Text(
                        'Helpful (${review.helpfulCount})',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 12),
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return timeago.format(date, locale: 'en_short');
    } catch (e) {
      return dateStr;
    }
  }
}
