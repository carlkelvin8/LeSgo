import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/api_service.dart';

class MerchantMission {
  final int id;
  final String title;
  final String description;
  final String reward;
  final double rewardAmount;
  final int currentProgress;
  final int goalTarget;
  final double progress;
  final bool isCompleted;
  final bool rewardClaimed;

  const MerchantMission({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.rewardAmount,
    required this.currentProgress,
    required this.goalTarget,
    required this.progress,
    required this.isCompleted,
    required this.rewardClaimed,
  });

  factory MerchantMission.fromJson(Map<String, dynamic> json) {
    return MerchantMission(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      reward: json['reward'] as String? ?? '',
      rewardAmount: (json['reward_amount'] as num?)?.toDouble() ?? 0.0,
      currentProgress: json['current_progress'] as int? ?? 0,
      goalTarget: json['goal_target'] as int? ?? 1,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      isCompleted: json['is_completed'] as bool? ?? false,
      rewardClaimed: json['reward_claimed'] as bool? ?? false,
    );
  }
}

class MerchantMissionState {
  final List<MerchantMission> missions;
  final bool isLoading;
  final String? error;

  const MerchantMissionState({
    this.missions = const [],
    this.isLoading = false,
    this.error,
  });

  MerchantMissionState copyWith({
    List<MerchantMission>? missions,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MerchantMissionState(
      missions: missions ?? this.missions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MerchantMissionNotifier extends StateNotifier<MerchantMissionState> {
  MerchantMissionNotifier() : super(const MerchantMissionState()) {
    loadMissions();
  }

  Future<void> loadMissions({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      print('🎯 Fetching merchant missions from API...');
      
      final data = await ApiService.getMerchantMissions();
      final missionsData = data['missions'] as List<dynamic>? ?? [];
      
      final missions = missionsData
          .map((m) => MerchantMission.fromJson(m as Map<String, dynamic>))
          .toList();

      print('✅ Loaded ${missions.length} merchant missions');
      
      state = state.copyWith(
        missions: missions,
        isLoading: false,
      );
    } catch (e) {
      print('❌ Error loading merchant missions: $e');
      state = state.copyWith(
        isLoading: false,
        error: ApiService.extractError(e),
      );
    }
  }

  Future<bool> claimReward(int missionId) async {
    try {
      print('💰 Claiming reward for merchant mission $missionId...');
      
      await ApiService.claimMerchantMissionReward(missionId);
      
      print('✅ Reward claimed successfully');
      
      // Reload missions to update state
      await loadMissions();
      
      return true;
    } catch (e) {
      print('❌ Error claiming reward: $e');
      state = state.copyWith(
        error: ApiService.extractError(e),
      );
      return false;
    }
  }
}

final merchantMissionProvider =
    StateNotifierProvider<MerchantMissionNotifier, MerchantMissionState>(
      (ref) => MerchantMissionNotifier(),
    );
