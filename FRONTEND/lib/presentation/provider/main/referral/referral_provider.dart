import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../data/data_source/referral_remote_datasource.dart';
import '../../missions/missions_provider.dart';
import '../profile/profile_provider.dart';

class ReferralDashboardState {
  final String referralCode;
  final int invitesSent;
  final int friendsJoined;
  final int pendingRewards;
  final int pointsEarned;
  final List<ReferralRewardDto> recentRewards;
  final bool isLoading;
  final String? error;
  final bool fromApi;

  const ReferralDashboardState({
    this.referralCode = '',
    this.invitesSent = 0,
    this.friendsJoined = 0,
    this.pendingRewards = 0,
    this.pointsEarned = 0,
    this.recentRewards = const [],
    this.isLoading = false,
    this.error,
    this.fromApi = false,
  });

  ReferralDashboardState copyWith({
    String? referralCode,
    int? invitesSent,
    int? friendsJoined,
    int? pendingRewards,
    int? pointsEarned,
    List<ReferralRewardDto>? recentRewards,
    bool? isLoading,
    String? error,
    bool? fromApi,
    bool clearError = false,
  }) {
    return ReferralDashboardState(
      referralCode: referralCode ?? this.referralCode,
      invitesSent: invitesSent ?? this.invitesSent,
      friendsJoined: friendsJoined ?? this.friendsJoined,
      pendingRewards: pendingRewards ?? this.pendingRewards,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      recentRewards: recentRewards ?? this.recentRewards,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      fromApi: fromApi ?? this.fromApi,
    );
  }
}

class ReferralDashboardNotifier extends StateNotifier<ReferralDashboardState> {
  ReferralDashboardNotifier(this._ref)
      : super(const ReferralDashboardState(isLoading: true)) {
    loadDashboard();
  }

  final Ref _ref;
  final ReferralRemoteDataSource _referralDs =
      getIt<ReferralRemoteDataSource>();

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final profile = _ref.read(profileProvider);
    final referralCode = profile.referralCode;

    try {
      final dashboard = await _referralDs.getDashboard();
      state = state.copyWith(
        referralCode: dashboard.referralCode.isNotEmpty
            ? dashboard.referralCode
            : referralCode,
        invitesSent: dashboard.invitesSent,
        friendsJoined: dashboard.friendsJoined,
        pendingRewards: dashboard.pendingRewards,
        pointsEarned: dashboard.pointsEarned > 0
            ? dashboard.pointsEarned
            : profile.points,
        recentRewards: dashboard.recentRewards,
        isLoading: false,
        fromApi: true,
      );
    } catch (e) {
      final mission = _ref.read(missionsProvider).missions.where(
            (m) => m.missionType.contains('referral'),
          );
      final referralMission = mission.isNotEmpty ? mission.first : null;

      state = state.copyWith(
        referralCode: referralCode,
        invitesSent: referralMission?.currentProgress ?? 0,
        friendsJoined: referralMission?.isCompleted == true ? 1 : 0,
        pendingRewards: referralMission != null &&
                referralMission.isCompleted &&
                !referralMission.rewardClaimed
            ? 1
            : 0,
        pointsEarned: profile.points,
        recentRewards: const [],
        isLoading: false,
        fromApi: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Live referral stats unavailable — showing your code and mission progress.',
          fallbackTl: 'Hindi available ang live stats — ipinapakita ang code at mission progress.',
        ),
      );
    }
  }
}

final referralDashboardProvider =
    StateNotifierProvider<ReferralDashboardNotifier, ReferralDashboardState>(
  (ref) => ReferralDashboardNotifier(ref),
);
