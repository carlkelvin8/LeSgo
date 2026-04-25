import 'package:json_annotation/json_annotation.dart';

part 'social_dto.g.dart';

@JsonSerializable()
class SocialShareDto {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'share_type')
  final String shareType;
  final String content;
  final String platform;
  @JsonKey(name: 'share_url')
  final String shareUrl;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  final int views;
  final int clicks;
  @JsonKey(name: 'created_at')
  final String createdAt;

  SocialShareDto({
    required this.id,
    required this.userId,
    required this.shareType,
    required this.content,
    required this.platform,
    required this.shareUrl,
    this.imageUrl,
    required this.views,
    required this.clicks,
    required this.createdAt,
  });

  factory SocialShareDto.fromJson(Map<String, dynamic> json) =>
      _$SocialShareDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SocialShareDtoToJson(this);
}

@JsonSerializable()
class SocialPlatformDto {
  final String id;
  final String name;
  @JsonKey(name: 'icon_url')
  final String iconUrl;
  @JsonKey(name: 'max_characters')
  final int maxCharacters;
  @JsonKey(name: 'supported_features')
  final List<String> supportedFeatures;

  SocialPlatformDto({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.maxCharacters,
    required this.supportedFeatures,
  });

  factory SocialPlatformDto.fromJson(Map<String, dynamic> json) =>
      _$SocialPlatformDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SocialPlatformDtoToJson(this);
}

@JsonSerializable()
class SocialStatisticsDto {
  @JsonKey(name: 'total_shares')
  final int totalShares;
  @JsonKey(name: 'total_views')
  final int totalViews;
  @JsonKey(name: 'total_clicks')
  final int totalClicks;
  @JsonKey(name: 'engagement_rate')
  final double engagementRate;

  SocialStatisticsDto({
    required this.totalShares,
    required this.totalViews,
    required this.totalClicks,
    required this.engagementRate,
  });

  factory SocialStatisticsDto.fromJson(Map<String, dynamic> json) =>
      _$SocialStatisticsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SocialStatisticsDtoToJson(this);
}

@JsonSerializable()
class ShareGeneratedDto {
  @JsonKey(name: 'share_id')
  final int shareId;
  @JsonKey(name: 'share_url')
  final String shareUrl;
  final String content;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'referral_code')
  final String? referralCode;

  ShareGeneratedDto({
    required this.shareId,
    required this.shareUrl,
    required this.content,
    this.imageUrl,
    this.referralCode,
  });

  factory ShareGeneratedDto.fromJson(Map<String, dynamic> json) =>
      _$ShareGeneratedDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ShareGeneratedDtoToJson(this);
}

@JsonSerializable()
class SocialAnalyticsDto {
  @JsonKey(name: 'my_shares')
  final int myShares;
  @JsonKey(name: 'total_views')
  final int totalViews;
  @JsonKey(name: 'total_clicks')
  final int totalClicks;
  @JsonKey(name: 'engagement_rate')
  final double engagementRate;
  @JsonKey(name: 'top_performing_share')
  final TopPerformingShareDto? topPerformingShare;

  SocialAnalyticsDto({
    required this.myShares,
    required this.totalViews,
    required this.totalClicks,
    required this.engagementRate,
    this.topPerformingShare,
  });

  factory SocialAnalyticsDto.fromJson(Map<String, dynamic> json) =>
      _$SocialAnalyticsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SocialAnalyticsDtoToJson(this);
}

@JsonSerializable()
class TopPerformingShareDto {
  final int id;
  final int views;
  final int clicks;

  TopPerformingShareDto({
    required this.id,
    required this.views,
    required this.clicks,
  });

  factory TopPerformingShareDto.fromJson(Map<String, dynamic> json) =>
      _$TopPerformingShareDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TopPerformingShareDtoToJson(this);
}
