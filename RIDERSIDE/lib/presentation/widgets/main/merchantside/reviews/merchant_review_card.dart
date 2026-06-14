import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../data/data_source/dto/merchant/review_dto.dart';
import '../../../common/menu_image_widget.dart';
import 'merchant_rating_stars_display.dart';

class MerchantReviewCard extends StatelessWidget {
  final ReviewDto review;

  const MerchantReviewCard({
    super.key,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8D9F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(context),
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? 'Customer',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        fontWeight: FontWeight.w700,
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
              MerchantRatingStarsDisplay(
                rating: review.rating.toDouble(),
                size: ResponsiveUtils.fontSize(context, 14),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            Text(
              review.comment!.trim(),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: Colors.black87,
                height: 1.45,
              ),
            ),
          ] else ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              'No written feedback',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 12),
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final photo = review.userPhoto;
    final fallback = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF5F2D82).withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(review.userName ?? 'C'),
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 13),
          fontWeight: FontWeight.w700,
          color: const Color(0xFF5F2D82),
        ),
      ),
    );

    if (photo == null || photo.trim().isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 40,
        height: 40,
        child: MenuImageWidget(
          source: photo,
          fit: BoxFit.cover,
          placeholder: fallback,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'C';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatDate(String value) {
    try {
      final date = DateTime.parse(value).toLocal();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (_) {
      return value;
    }
  }
}
