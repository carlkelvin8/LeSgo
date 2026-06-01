import 'package:injectable/injectable.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';

class ReferralDashboardDto {
  final String referralCode;
  final int invitesSent;
  final int friendsJoined;
  final int pendingRewards;
  final int pointsEarned;
  final List<ReferralRewardDto> recentRewards;

  const ReferralDashboardDto({
    required this.referralCode,
    required this.invitesSent,
    required this.friendsJoined,
    required this.pendingRewards,
    required this.pointsEarned,
    required this.recentRewards,
  });

  factory ReferralDashboardDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? json['data'] as Map : json;
    final rewardsRaw = data['recent_rewards'] ?? data['rewards'];
    final rewards = rewardsRaw is List
        ? rewardsRaw
            .whereType<Map>()
            .map((e) => ReferralRewardDto.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <ReferralRewardDto>[];

    return ReferralDashboardDto(
      referralCode: data['referral_code']?.toString() ?? '',
      invitesSent: _int(data['invites_sent'] ?? data['total_invites']),
      friendsJoined: _int(data['friends_joined'] ?? data['successful_referrals']),
      pendingRewards: _int(data['pending_rewards'] ?? data['pending']),
      pointsEarned: _int(data['points_earned'] ?? data['total_points']),
      recentRewards: rewards,
    );
  }

  static int _int(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ReferralRewardDto {
  final String title;
  final String status;
  final int points;
  final String? date;

  const ReferralRewardDto({
    required this.title,
    required this.status,
    required this.points,
    this.date,
  });

  factory ReferralRewardDto.fromJson(Map<String, dynamic> json) {
    return ReferralRewardDto(
      title: json['title']?.toString() ?? json['friend_name']?.toString() ?? 'Referral',
      status: json['status']?.toString() ?? 'pending',
      points: ReferralDashboardDto._int(json['points'] ?? json['reward_points']),
      date: json['date']?.toString() ?? json['created_at']?.toString(),
    );
  }
}

@lazySingleton
class ReferralRemoteDataSource {
  final DioClient _dioClient;

  ReferralRemoteDataSource(this._dioClient);

  Future<ReferralDashboardDto> getDashboard() async {
    final response = await _dioClient.dio.get(ApiConstants.referralDashboard);
    final body = response.data as Map<String, dynamic>;
    return ReferralDashboardDto.fromJson(body);
  }
}
