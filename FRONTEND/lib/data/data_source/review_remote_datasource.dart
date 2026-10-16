import 'package:injectable/injectable.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/review/reviews_response_dto.dart';
import 'dto/review/create_review_request_dto.dart';

@lazySingleton
class ReviewRemoteDataSource {
  final DioClient _dioClient;

  ReviewRemoteDataSource(this._dioClient);

  /// Get reviews for a partner
  Future<ReviewsResponseDto> getPartnerReviews(
    int partnerId, {
    int perPage = 20,
  }) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get(
        ApiConstants.partnerReviews(partnerId),
        queryParameters: {'per_page': perPage},
      );
      return ReviewsResponseDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get reviews: $e');
    }
  }

  /// Create a review for an order
  Future<bool> createReview(CreateReviewRequestDto request) async {
    final dio = _dioClient.dio;
    try {
      await dio.post('/v1/reviews', data: request.toJson());
      return true;
    } catch (e) {
      throw Exception('Failed to create review: $e');
    }
  }

  /// Get reviews with pagination
  Future<ReviewsResponseDto> getReviews({
    String? reviewableType,
    int? reviewableId,
    int page = 1,
    int perPage = 20,
  }) async {
    final dio = _dioClient.dio;
    try {
      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      if (reviewableId != null && reviewableType == 'driver') {
        queryParams['driver_id'] = reviewableId;
      } else if (reviewableId != null && reviewableType == 'service') {
        queryParams['service_id'] = reviewableId;
      }

      final response = await dio.get(
        '/v1/reviews',
        queryParameters: queryParams,
      );
      return ReviewsResponseDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get reviews: $e');
    }
  }

  /// Get review statistics
  Future<ReviewStatisticsResponseDto> getStatistics({
    String? reviewableType,
    int? reviewableId,
  }) async {
    final dio = _dioClient.dio;
    try {
      final queryParams = <String, dynamic>{};

      if (reviewableId != null && reviewableType == 'driver') {
        queryParams['driver_id'] = reviewableId;
      } else if (reviewableId != null && reviewableType == 'service') {
        queryParams['service_id'] = reviewableId;
      }

      final response = await dio.get(
        '/v1/reviews/statistics',
        queryParameters: queryParams,
      );
      return ReviewStatisticsResponseDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }

  /// Mark a review as helpful
  Future<void> markHelpful(int reviewId) async {
    final dio = _dioClient.dio;
    try {
      await dio.post('/v1/reviews/$reviewId/helpful');
    } catch (e) {
      throw Exception('Failed to mark review as helpful: $e');
    }
  }
}
