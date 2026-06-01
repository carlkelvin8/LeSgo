import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../data/data_source/loyalty_remote_datasource.dart';
import '../../../../data/data_source/voucher_remote_datasource.dart';
import '../profile/profile_provider.dart';

class LoyaltyReward {
  final int id;
  final String title;
  final String description;
  final int pointsCost;
  final String rewardType;

  const LoyaltyReward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.rewardType,
  });

  factory LoyaltyReward.fromDto(LoyaltyRewardDto dto) {
    return LoyaltyReward(
      id: dto.id,
      title: dto.title,
      description: dto.description,
      pointsCost: dto.pointsCost,
      rewardType: dto.rewardType,
    );
  }
}

class LoyaltyState {
  final List<LoyaltyReward> rewards;
  final bool isLoading;
  final bool isRedeeming;
  final String? error;
  final String? infoMessage;
  final bool rewardsFromApi;

  const LoyaltyState({
    this.rewards = const [],
    this.isLoading = false,
    this.isRedeeming = false,
    this.error,
    this.infoMessage,
    this.rewardsFromApi = false,
  });

  LoyaltyState copyWith({
    List<LoyaltyReward>? rewards,
    bool? isLoading,
    bool? isRedeeming,
    String? error,
    String? infoMessage,
    bool? rewardsFromApi,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return LoyaltyState(
      rewards: rewards ?? this.rewards,
      isLoading: isLoading ?? this.isLoading,
      isRedeeming: isRedeeming ?? this.isRedeeming,
      error: clearError ? null : (error ?? this.error),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
      rewardsFromApi: rewardsFromApi ?? this.rewardsFromApi,
    );
  }
}

class LoyaltyNotifier extends StateNotifier<LoyaltyState> {
  LoyaltyNotifier(this._ref) : super(const LoyaltyState(isLoading: true)) {
    loadRewards();
  }

  final Ref _ref;
  final LoyaltyRemoteDataSource _loyaltyDs = getIt<LoyaltyRemoteDataSource>();
  final VoucherRemoteDataSource _voucherDs = getIt<VoucherRemoteDataSource>();

  Future<void> loadRewards() async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);

    try {
      final rewards = await _loyaltyDs.getRewards();
      if (rewards.isNotEmpty) {
        state = state.copyWith(
          rewards: rewards.map(LoyaltyReward.fromDto).toList(),
          isLoading: false,
          rewardsFromApi: true,
        );
        return;
      }
      throw Exception('No loyalty rewards returned');
    } catch (e) {
      try {
        final voucherResponse = await _voucherDs.getAvailableVouchers();
        final mapped = voucherResponse.data.asMap().entries.map((entry) {
          final voucher = entry.value;
          final points = (voucher.minOrder * 5).round().clamp(50, 500);
          return LoyaltyReward(
            id: entry.key + 1,
            title: voucher.title,
            description: voucher.description,
            pointsCost: points,
            rewardType: 'voucher',
          );
        }).toList();

        state = state.copyWith(
          rewards: mapped,
          isLoading: false,
          rewardsFromApi: false,
          infoMessage: mapped.isEmpty
              ? null
              : 'Preview catalog only — redeem when loyalty sync is available.',
        );
      } catch (_) {
        state = state.copyWith(
          isLoading: false,
          error: ApiErrorMapper.message(
            e,
            fallbackEn: 'Could not load rewards. Pull to retry.',
            fallbackTl: 'Hindi ma-load ang rewards. Subukan muli.',
          ),
        );
      }
    }
  }

  Future<bool> redeemReward(LoyaltyReward reward, int userPoints) async {
    if (userPoints < reward.pointsCost) {
      state = state.copyWith(
        error: 'You need ${reward.pointsCost} points. You have $userPoints.',
      );
      return false;
    }

    state = state.copyWith(isRedeeming: true, clearError: true);

    try {
      final result = await _loyaltyDs.redeemReward(reward.id);
      if (result.remainingPoints != null) {
        _ref.read(profileProvider.notifier).refreshProfile();
      } else {
        await _ref.read(profileProvider.notifier).refreshProfile();
      }
      state = state.copyWith(isRedeeming: false);
      return result.success;
    } catch (e) {
      state = state.copyWith(
        isRedeeming: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Redemption failed. Please try again.',
          fallbackTl: 'Hindi na-redeem. Subukan muli.',
        ),
      );
      return false;
    }
  }
}

final loyaltyProvider =
    StateNotifierProvider<LoyaltyNotifier, LoyaltyState>((ref) {
  return LoyaltyNotifier(ref);
});
