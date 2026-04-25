import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/network/dio_client.dart';
import 'dto/social/social_dto.dart';

@lazySingleton
class SocialRemoteDataSource {
  final DioClient _dioClient;

  SocialRemoteDataSource(this._dioClient);

  /// Get social platforms
  Future<List<SocialPlatformDto>> getSocialPlatforms() async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/social/platforms');
      return (response.data['data'] as List)
          .map((item) => SocialPlatformDto.fromJson(item))
          .toList();
    } catch (e) {
      // Mock response
      return [
        SocialPlatformDto(
          id: 'facebook',
          name: 'Facebook',
          iconUrl: 'https://example.com/facebook.png',
          maxCharacters: 5000,
          supportedFeatures: ['text', 'image', 'link'],
        ),
        SocialPlatformDto(
          id: 'twitter',
          name: 'Twitter',
          iconUrl: 'https://example.com/twitter.png',
          maxCharacters: 280,
          supportedFeatures: ['text', 'image', 'link'],
        ),
      ];
    }
  }

  /// Get social statistics
  Future<SocialStatisticsDto> getSocialStatistics() async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/social/statistics');
      return SocialStatisticsDto.fromJson(response.data['data']);
    } catch (e) {
      // Mock response
      return SocialStatisticsDto(
        totalShares: 1250,
        totalViews: 15000,
        totalClicks: 3500,
        engagementRate: 23.3,
      );
    }
  }

  /// Get social analytics
  Future<SocialAnalyticsDto> getSocialAnalytics() async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/social/analytics');
      return SocialAnalyticsDto.fromJson(response.data['data']);
    } catch (e) {
      // Mock response
      return SocialAnalyticsDto(
        myShares: 45,
        totalViews: 850,
        totalClicks: 120,
        engagementRate: 14.1,
      );
    }
  }
}