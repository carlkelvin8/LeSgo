import 'package:injectable/injectable.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';

class LoyaltyRewardDto {
  final int id;
  final String title;
  final String description;
  final int pointsCost;
  final String rewardType;
  final bool available;

  const LoyaltyRewardDto({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.rewardType,
    this.available = true,
  });

  factory LoyaltyRewardDto.fromJson(Map<String, dynamic> json) {
    return LoyaltyRewardDto(
      id: json['id'] as int? ?? int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Reward',
      description: json['description']?.toString() ?? '',
      pointsCost: _parsePoints(
        json['points_cost'] ?? json['points_required'] ?? json['cost'],
      ),
      rewardType: json['reward_type']?.toString() ?? json['type']?.toString() ?? 'voucher',
      available: json['available'] as bool? ?? json['is_available'] as bool? ?? true,
    );
  }

  static int _parsePoints(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class LoyaltyRedeemResultDto {
  final bool success;
  final String message;
  final int? remainingPoints;

  const LoyaltyRedeemResultDto({
    required this.success,
    required this.message,
    this.remainingPoints,
  });

  factory LoyaltyRedeemResultDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    int? remaining;
    if (data is Map) {
      remaining = LoyaltyRewardDto._parsePoints(
        data['remaining_points'] ?? data['points'],
      );
    }
    return LoyaltyRedeemResultDto(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? 'Reward redeemed.',
      remainingPoints: remaining,
    );
  }
}

@lazySingleton
class LoyaltyRemoteDataSource {
  final DioClient _dioClient;

  LoyaltyRemoteDataSource(this._dioClient);

  Future<List<LoyaltyRewardDto>> getRewards() async {
    final response = await _dioClient.dio.get(ApiConstants.loyaltyRewards);
    final body = response.data as Map<String, dynamic>;
    final raw = body['data'];
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) => LoyaltyRewardDto.fromJson(Map<String, dynamic>.from(item)))
        .where((reward) => reward.id > 0 && reward.pointsCost > 0)
        .toList();
  }

  Future<LoyaltyRedeemResultDto> redeemReward(int rewardId) async {
    final response = await _dioClient.dio.post(
      ApiConstants.loyaltyRedeem(rewardId),
    );
    return LoyaltyRedeemResultDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
