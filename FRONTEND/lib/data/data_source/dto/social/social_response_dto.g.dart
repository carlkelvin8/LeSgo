// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SocialShareResponseDto _$SocialShareResponseDtoFromJson(
  Map<String, dynamic> json,
) => SocialShareResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: SocialShareDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SocialShareResponseDtoToJson(
  SocialShareResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

SocialPlatformsResponseDto _$SocialPlatformsResponseDtoFromJson(
  Map<String, dynamic> json,
) => SocialPlatformsResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: (json['data'] as List<dynamic>)
      .map((e) => SocialPlatformDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SocialPlatformsResponseDtoToJson(
  SocialPlatformsResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

SocialStatisticsResponseDto _$SocialStatisticsResponseDtoFromJson(
  Map<String, dynamic> json,
) => SocialStatisticsResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: SocialStatisticsDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SocialStatisticsResponseDtoToJson(
  SocialStatisticsResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

ShareGeneratedResponseDto _$ShareGeneratedResponseDtoFromJson(
  Map<String, dynamic> json,
) => ShareGeneratedResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: ShareGeneratedDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ShareGeneratedResponseDtoToJson(
  ShareGeneratedResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

SocialSharesResponseDto _$SocialSharesResponseDtoFromJson(
  Map<String, dynamic> json,
) => SocialSharesResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: (json['data'] as List<dynamic>)
      .map((e) => SocialShareDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: json['meta'] == null
      ? null
      : PaginationMetaDto.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SocialSharesResponseDtoToJson(
  SocialSharesResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
  'meta': instance.meta,
};

SocialAnalyticsResponseDto _$SocialAnalyticsResponseDtoFromJson(
  Map<String, dynamic> json,
) => SocialAnalyticsResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String?,
  data: SocialAnalyticsDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SocialAnalyticsResponseDtoToJson(
  SocialAnalyticsResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

PaginationMetaDto _$PaginationMetaDtoFromJson(Map<String, dynamic> json) =>
    PaginationMetaDto(
      currentPage: (json['current_page'] as num).toInt(),
      lastPage: (json['last_page'] as num).toInt(),
      perPage: (json['per_page'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$PaginationMetaDtoToJson(PaginationMetaDto instance) =>
    <String, dynamic>{
      'current_page': instance.currentPage,
      'last_page': instance.lastPage,
      'per_page': instance.perPage,
      'total': instance.total,
    };
