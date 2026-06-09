// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MissionDto _$MissionDtoFromJson(Map<String, dynamic> json) => MissionDto(
  id: _parseInt(json['id']),
  userId: _parseInt(json['user_id']),
  missionType: json['mission_type'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  currentProgress: _parseInt(json['current_progress']),
  goalTarget: _parseInt(json['goal_target']),
  isCompleted: _parseBool(json['is_completed']),
  completedAt: json['completed_at'] as String?,
  rewardType: json['reward_type'] as String,
  rewardValue: _parseDouble(json['reward_value']),
  rewardClaimed: _parseBool(json['reward_claimed']),
  claimedAt: json['claimed_at'] as String?,
  missionDate: json['mission_date'] as String,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$MissionDtoToJson(MissionDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'mission_type': instance.missionType,
      'title': instance.title,
      'description': instance.description,
      'current_progress': instance.currentProgress,
      'goal_target': instance.goalTarget,
      'is_completed': instance.isCompleted,
      'completed_at': instance.completedAt,
      'reward_type': instance.rewardType,
      'reward_value': instance.rewardValue,
      'reward_claimed': instance.rewardClaimed,
      'claimed_at': instance.claimedAt,
      'mission_date': instance.missionDate,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

MissionsResponseDto _$MissionsResponseDtoFromJson(Map<String, dynamic> json) =>
    MissionsResponseDto(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => MissionDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MissionsResponseDtoToJson(
  MissionsResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

ClaimMissionResponseDto _$ClaimMissionResponseDtoFromJson(
  Map<String, dynamic> json,
) => ClaimMissionResponseDto(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: MissionDto.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ClaimMissionResponseDtoToJson(
  ClaimMissionResponseDto instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};
