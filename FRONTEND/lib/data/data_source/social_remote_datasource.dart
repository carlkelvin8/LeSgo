import 'package:injectable/injectable.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/social/social_dto.dart';

@lazySingleton
class SocialRemoteDataSource {
  final DioClient _dioClient;

  SocialRemoteDataSource(this._dioClient);

  Future<List<SocialPlatformDto>> getSocialPlatforms() async {
    final response = await _dioClient.dio.get('/v1/social/platforms');
    return (response.data['data'] as List)
        .map((item) => SocialPlatformDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SocialStatisticsDto> getSocialStatistics() async {
    final response = await _dioClient.dio.get('/v1/social/statistics');
    return SocialStatisticsDto.fromJson(response.data['data']);
  }

  Future<SocialAnalyticsDto> getSocialAnalytics() async {
    final response = await _dioClient.dio.get('/v1/social/analytics');
    return SocialAnalyticsDto.fromJson(response.data['data']);
  }

  Future<ShareGeneratedDto> generateReferralShare({String platform = 'facebook'}) async {
    final response = await _dioClient.dio.post(
      ApiConstants.socialReferralShare,
      data: {'platform': platform},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ShareGeneratedDto(
      shareId: (data['id'] as num?)?.toInt() ?? 0,
      shareUrl: data['share_url']?.toString() ?? '',
      content: data['share_description']?.toString() ?? '',
      imageUrl: data['share_image_url']?.toString(),
      referralCode: data['share_metadata'] is Map
          ? (data['share_metadata']['referral_code']?.toString())
          : null,
    );
  }

  Future<void> confirmSocialFollow({String platform = 'facebook'}) async {
    await _dioClient.dio.post(
      ApiConstants.socialFollowConfirm,
      data: {'platform': platform},
    );
  }

  Future<void> trackShareEngagement(int shareId, {required String action}) async {
    await _dioClient.dio.post(
      '/v1/social/shares/$shareId/track',
      data: {'event': action},
    );
  }
}
