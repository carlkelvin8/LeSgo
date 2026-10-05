import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../provider/review/review_provider.dart';
import 'rating_stars.dart';

/// Reusable rating dialog
/// Shows a dialog for users to rate and review
class RatingDialog extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final String reviewableType;
  final int reviewableId;
  final VoidCallback? onSuccess;

  const RatingDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.reviewableType,
    required this.reviewableId,
    this.onSuccess,
  });

  @override
  ConsumerState<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends ConsumerState<RatingDialog> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    final reviewNotifier = ref.read(reviewProvider.notifier);

    final success = await reviewNotifier.submitReview(
      reviewableType: widget.reviewableType,
      reviewableId: widget.reviewableId,
      rating: _rating,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      context: context,
    );

    if (success && mounted) {
      Navigator.of(context).pop(true);
      widget.onSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(reviewProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              widget.title,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 18),
                fontWeight: FontWeight.w700,
                color: AppColors.foreground(context, Colors.black87),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),

            // Subtitle
            Text(
              widget.subtitle,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: AppColors.foreground(context, Colors.grey.shade600),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            // Star Rating
            RatingStars(
              rating: _rating,
              onRatingChanged: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
              size: 40,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            // Comment TextField
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Share your feedback (optional)',
                hintStyle: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  color: AppColors.foreground(context, Colors.grey.shade500),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border(context, Colors.grey.shade300)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF5F2D82)),
                ),
                contentPadding: EdgeInsets.all(
                  ResponsiveUtils.spacing(context, 16),
                ),
              ),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: reviewState.isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF5F2D82)),
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.spacing(context, 14),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent(context, Color(0xFF5F2D82)),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                Expanded(
                  child: ElevatedButton(
                    onPressed: reviewState.isSubmitting ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F2D82),
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.spacing(context, 14),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: reviewState.isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Submit',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 16),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show rating dialog
Future<bool?> showRatingDialog({
  required BuildContext context,
  required String title,
  required String subtitle,
  required String reviewableType,
  required int reviewableId,
  VoidCallback? onSuccess,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => RatingDialog(
      title: title,
      subtitle: subtitle,
      reviewableType: reviewableType,
      reviewableId: reviewableId,
      onSuccess: onSuccess,
    ),
  );
}
