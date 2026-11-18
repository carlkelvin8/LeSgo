import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lesgo/core/state/user_session_epoch.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../data/data_source/referral_remote_datasource.dart';
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

  const ReferralDashboardState({
    this.referralCode = '',
    this.invitesSent = 0,
    this.friendsJoined = 0,
    this.pendingRewards = 0,
    this.pointsEarned = 0,
    this.recentRewards = const [],
    this.isLoading = false,
    this.error,
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

    try {
      final dashboard = await _referralDs.getDashboard();
      final profile = _ref.read(profileProvider);

      state = state.copyWith(
        referralCode: dashboard.referralCode.isNotEmpty
            ? dashboard.referralCode
            : profile.referralCode,
        invitesSent: dashboard.invitesSent,
        friendsJoined: dashboard.friendsJoined,
        pendingRewards: dashboard.pendingRewards,
        pointsEarned: dashboard.pointsEarned,
        recentRewards: dashboard.recentRewards,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not load referral stats. Pull to retry.',
          fallbackTl: 'Hindi ma-load ang referral stats. Subukan muli.',
        ),
      );
    }
  }
}

final referralDashboardProvider =
    StateNotifierProvider<ReferralDashboardNotifier, ReferralDashboardState>(
  (ref) {
    // Rebuild (and refetch) when the signed-in user changes.
    ref.watch(userSessionEpochProvider);
    return ReferralDashboardNotifier(ref);
  },
);

/// Formats a raw ISO timestamp as a readable local date; falls back to the
/// original text when it cannot be parsed.
String formatReferralRewardDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return DateFormat('MMM d, y').format(parsed.toLocal());
}

/// "pending" -> "Pending".
String capitalizeReferralStatus(String status) {
  final t = status.trim();
  if (t.isEmpty) return t;
  return t[0].toUpperCase() + t.substring(1).toLowerCase();
}
