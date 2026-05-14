import 'package:json_annotation/json_annotation.dart';

part 'mission_dto.g.dart';

@JsonSerializable()
class MissionDto {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'mission_type')
  final String missionType;
  final String title;
  final String? description;
  @JsonKey(name: 'current_progress')
  final int currentProgress;
  @JsonKey(name: 'goal_target')
  final int goalTarget;
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  @JsonKey(name: 'completed_at')
  final String? completedAt;
  @JsonKey(name: 'reward_type')
  final String rewardType;
  @JsonKey(name: 'reward_value')
  final double rewardValue;
  @JsonKey(name: 'reward_claimed')
  final bool rewardClaimed;
  @JsonKey(name: 'claimed_at')
  final String? claimedAt;
  @JsonKey(name: 'mission_date')
  final String missionDate;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  MissionDto({
    required this.id,
    required this.userId,
    required this.missionType,
    required this.title,
    this.description,
    required this.currentProgress,
    required this.goalTarget,
    required this.isCompleted,
    this.completedAt,
    required this.rewardType,
    required this.rewardValue,
    required this.rewardClaimed,
    this.claimedAt,
    required this.missionDate,
    this.createdAt,
    this.updatedAt,
  });

  factory MissionDto.fromJson(Map<String, dynamic> json) => _$MissionDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MissionDtoToJson(this);

  double get progressPercentage => goalTarget > 0 ? (currentProgress / goalTarget).clamp(0.0, 1.0) : 0.0;
}

@JsonSerializable()
class MissionsResponseDto {
  final bool success;
  final String message;
  final List<MissionDto> data;

  MissionsResponseDto({
    required this.success,
    required this.message,
    required this.data,
  });

  factory MissionsResponseDto.fromJson(Map<String, dynamic> json) => _$MissionsResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MissionsResponseDtoToJson(this);
}

@JsonSerializable()
class ClaimMissionResponseDto {
  final bool success;
  final String message;
  final MissionDto data;

  ClaimMissionResponseDto({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ClaimMissionResponseDto.fromJson(Map<String, dynamic> json) => _$ClaimMissionResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ClaimMissionResponseDtoToJson(this);
}