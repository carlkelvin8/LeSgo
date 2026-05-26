import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/data_source/review_remote_datasource.dart';
import '../../../data/data_source/dto/review/review_dto.dart';
import '../../../data/data_source/dto/review/create_review_request_dto.dart';
import '../../../data/data_source/dto/review/reviews_response_dto.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../../../core/utils/snackbar_utils.dart';

class ReviewState {
  final List<ReviewDto> reviews;
  final ReviewStatisticsDto? statistics;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  ReviewState({
    this.reviews = const [],
    this.statistics,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  ReviewState copyWith({
    List<ReviewDto>? reviews,
    ReviewStatisticsDto? statistics,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) {
    return ReviewState(
      reviews: reviews ?? this.reviews,
      statistics: statistics ?? this.statistics,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class ReviewNotifier extends StateNotifier<ReviewState> {
  ReviewNotifier() : super(ReviewState());

  /// Load reviews for a specific item (order, partner, driver)
  Future<void> loadReviews({
    String? reviewableType,
    int? reviewableId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final reviewDataSource = getIt<ReviewRemoteDataSource>();
      final response = await reviewDataSource.getReviews(
        reviewableType: reviewableType,
        reviewableId: reviewableId,
      );

      if (response.success) {
        state = state.copyWith(
          reviews: response.data,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          reviews: [],
          isLoading: false,
          error: 'Failed to load reviews',
        );
      }
    } catch (e) {
      state = state.copyWith(
        reviews: [],
        isLoading: false,
        error: ApiErrorMapper.message(e),
      );
    }
  }

  /// Load review statistics
  Future<void> loadStatistics({
    String? reviewableType,
    int? reviewableId,
  }) async {
    try {
      final reviewDataSource = getIt<ReviewRemoteDataSource>();
      final response = await reviewDataSource.getStatistics(
        reviewableType: reviewableType,
        reviewableId: reviewableId,
      );

      if (response.success) {
        state = state.copyWith(statistics: response.data);
      }
    } catch (e) {
      // Silently fail for statistics
    }
  }

  /// Submit a review
  Future<bool> submitReview({
    required String reviewableType,
    required int reviewableId,
    required int rating,
    String? comment,
    BuildContext? context,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final reviewDataSource = getIt<ReviewRemoteDataSource>();
      final request = CreateReviewRequestDto(
        reviewableType: reviewableType,
        reviewableId: reviewableId,
        rating: rating,
        comment: comment,
      );

      final response = await reviewDataSource.createReview(request);

      if (response.success) {
        state = state.copyWith(isSubmitting: false);

        if (context != null && context.mounted) {
          SnackBarUtils.showSuccess(context, 'Review submitted successfully!');
        }

        // Reload reviews
        await loadReviews(
          reviewableType: reviewableType,
          reviewableId: reviewableId,
        );

        return true;
      } else {
        state = state.copyWith(
          isSubmitting: false,
          error: 'Failed to submit review',
        );

        if (context != null && context.mounted) {
          SnackBarUtils.showError(context, 'Failed to submit review');
        }
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: ApiErrorMapper.message(e),
      );

      if (context != null && context.mounted) {
        SnackBarUtils.showErrorFrom(context, e);
      }
      return false;
    }
  }

  /// Mark review as helpful
  Future<void> markHelpful(int reviewId) async {
    try {
      final reviewDataSource = getIt<ReviewRemoteDataSource>();
      await reviewDataSource.markHelpful(reviewId);

      // Update local state
      final updatedReviews = state.reviews.map((review) {
        if (review.id == reviewId) {
          return ReviewDto(
            id: review.id,
            userId: review.userId,
            reviewableType: review.reviewableType,
            reviewableId: review.reviewableId,
            rating: review.rating,
            comment: review.comment,
            helpfulCount: review.helpfulCount + 1,
            createdAt: review.createdAt,
            updatedAt: review.updatedAt,
            userName: review.userName,
            userPhoto: review.userPhoto,
          );
        }
        return review;
      }).toList();

      state = state.copyWith(reviews: updatedReviews);
    } catch (e) {
      // Silently fail
    }
  }
}

final reviewProvider =
    StateNotifierProvider<ReviewNotifier, ReviewState>((ref) {
  return ReviewNotifier();
});
