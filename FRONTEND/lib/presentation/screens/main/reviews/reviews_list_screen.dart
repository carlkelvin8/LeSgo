import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive_utils.dart';
// import '../../../provider/review/review_provider.dart'; // Temporarily commented out
import '../../../widgets/widgets.dart';

/// Screen to display reviews for a specific item (restaurant, store, driver)
class ReviewsListScreen extends ConsumerStatefulWidget {
  final String title;
  final String reviewableType;
  final int reviewableId;

  const ReviewsListScreen({
    super.key,
    required this.title,
    required this.reviewableType,
    required this.reviewableId,
  });

  @override
  ConsumerState<ReviewsListScreen> createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends ConsumerState<ReviewsListScreen> {
  @override
  void initState() {
    super.initState();
    // Load reviews on init
    Future.microtask(() {
      ref.read(reviewProvider.notifier).loadReviews(
            reviewableType: widget.reviewableType,
            reviewableId: widget.reviewableId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(reviewProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: reviewState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : reviewState.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                        Text(
                          'Failed to load reviews',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 16),
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(reviewProvider.notifier).loadReviews(
                                  reviewableType: widget.reviewableType,
                                  reviewableId: widget.reviewableId,
                                );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5F2D82),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : reviewState.reviews.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 16),
                            ),
                            Text(
                              'No reviews yet',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 16),
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 8),
                            ),
                            Text(
                              'Be the first to leave a review!',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 14),
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await ref.read(reviewProvider.notifier).loadReviews(
                                reviewableType: widget.reviewableType,
                                reviewableId: widget.reviewableId,
                              );
                        },
                        child: ListView.builder(
                          padding: EdgeInsets.all(
                            ResponsiveUtils.spacing(context, 16),
                          ),
                          itemCount: reviewState.reviews.length,
                          itemBuilder: (context, index) {
                            final review = reviewState.reviews[index];
                            return ReviewCard(
                              review: review,
                              onHelpful: () {
                                ref
                                    .read(reviewProvider.notifier)
                                    .markHelpful(review.id);
                              },
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
