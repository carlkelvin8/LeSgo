// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SocialShareDto _$SocialShareDtoFromJson(Map<String, dynamic> json) =>
    SocialShareDto(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      shareType: json['share_type'] as String,
      content: json['content'] as String,
      platform: json['platform'] as String,
      shareUrl: json['share_url'] as String,
      imageUrl: json['image_url'] as String?,
      views: (json['views'] as num).toInt(),
      clicks: (json['clicks'] as num).toInt(),
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$SocialShareDtoToJson(SocialShareDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'share_type': instance.shareType,
      'content': instance.content,
      'platform': instance.platform,
      'share_url': instance.shareUrl,
      'image_url': instance.imageUrl,
      'views': instance.views,
      'clicks': instance.clicks,
      'created_at': instance.createdAt,
    };

SocialPlatformDto _$SocialPlatformDtoFromJson(Map<String, dynamic> json) =>
    SocialPlatformDto(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['icon_url'] as String,
      maxCharacters: (json['max_characters'] as num).toInt(),
      supportedFeatures: (json['supported_features'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SocialPlatformDtoToJson(SocialPlatformDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon_url': instance.iconUrl,
      'max_characters': instance.maxCharacters,
      'supported_features': instance.supportedFeatures,
    };

SocialStatisticsDto _$SocialStatisticsDtoFromJson(Map<String, dynamic> json) =>
    SocialStatisticsDto(
      totalShares: (json['total_shares'] as num).toInt(),
      totalViews: (json['total_views'] as num).toInt(),
      totalClicks: (json['total_clicks'] as num).toInt(),
      engagementRate: (json['engagement_rate'] as num).toDouble(),
    );

Map<String, dynamic> _$SocialStatisticsDtoToJson(
  SocialStatisticsDto instance,
) => <String, dynamic>{
  'total_shares': instance.totalShares,
  'total_views': instance.totalViews,
  'total_clicks': instance.totalClicks,
  'engagement_rate': instance.engagementRate,
};

ShareGeneratedDto _$ShareGeneratedDtoFromJson(Map<String, dynamic> json) =>
    ShareGeneratedDto(
      shareId: (json['share_id'] as num).toInt(),
      shareUrl: json['share_url'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      referralCode: json['referral_code'] as String?,
    );

Map<String, dynamic> _$ShareGeneratedDtoToJson(ShareGeneratedDto instance) =>
    <String, dynamic>{
      'share_id': instance.shareId,
      'share_url': instance.shareUrl,
      'content': instance.content,
      'image_url': instance.imageUrl,
      'referral_code': instance.referralCode,
    };

SocialAnalyticsDto _$SocialAnalyticsDtoFromJson(Map<String, dynamic> json) =>
    SocialAnalyticsDto(
      myShares: (json['my_shares'] as num).toInt(),
      totalViews: (json['total_views'] as num).toInt(),
      totalClicks: (json['total_clicks'] as num).toInt(),
      engagementRate: (json['engagement_rate'] as num).toDouble(),
      topPerformingShare: json['top_performing_share'] == null
          ? null
          : TopPerformingShareDto.fromJson(
              json['top_performing_share'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$SocialAnalyticsDtoToJson(SocialAnalyticsDto instance) =>
    <String, dynamic>{
      'my_shares': instance.myShares,
      'total_views': instance.totalViews,
      'total_clicks': instance.totalClicks,
      'engagement_rate': instance.engagementRate,
      'top_performing_share': instance.topPerformingShare,
    };

TopPerformingShareDto _$TopPerformingShareDtoFromJson(
  Map<String, dynamic> json,
) => TopPerformingShareDto(
  id: (json['id'] as num).toInt(),
  views: (json['views'] as num).toInt(),
  clicks: (json['clicks'] as num).toInt(),
);

Map<String, dynamic> _$TopPerformingShareDtoToJson(
  TopPerformingShareDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'views': instance.views,
  'clicks': instance.clicks,
};
