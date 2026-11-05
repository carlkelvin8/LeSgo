import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../../core/utils/app_logger.dart';
import 'rider_wallet_provider.dart';

class RiderMission {
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

  const RiderMission({
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

  factory RiderMission.fromJson(Map<String, dynamic> json) {
    final goal = _mInt(json['goal_target'], 1);
    return RiderMission(
      id: _mInt(json['id'], 0),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      reward: json['reward']?.toString() ?? '',
      rewardAmount: _mDouble(json['reward_amount']),
      currentProgress: _mInt(json['current_progress'], 0),
      goalTarget: goal <= 0 ? 1 : goal,
      progress: _mDouble(json['progress']),
      isCompleted: _mBool(json['is_completed']),
      rewardClaimed: _mBool(json['reward_claimed']),
    );
  }
}

int _mInt(dynamic v, int fallback) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? fallback;
  return fallback;
}

double _mDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

bool _mBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

class RiderMissionState {
  final List<RiderMission> missions;
  final bool isLoading;
  final String? error;

  const RiderMissionState({
    this.missions = const [],
    this.isLoading = false,
    this.error,
  });

  RiderMissionState copyWith({
    List<RiderMission>? missions,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RiderMissionState(
      missions: missions ?? this.missions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RiderMissionNotifier extends StateNotifier<RiderMissionState> {
  final Ref _ref;

  RiderMissionNotifier(this._ref) : super(const RiderMissionState()) {
    loadMissions();
  }

  Future<void> loadMissions({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      AppLogger.debug('Fetching missions from API');
      
      final data = await ApiService.getDriverMissions();
      final rawMissions = data['missions'];
      final missionsData = rawMissions is List ? rawMissions : const [];

      final missions = missionsData
          .whereType<Map>()
          .map((m) => RiderMission.fromJson(Map<String, dynamic>.from(m)))
          .toList();

      AppLogger.debug('Loaded ${missions.length} missions');
      
      state = state.copyWith(
        missions: missions,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('Error loading missions', e);
      state = state.copyWith(
        isLoading: false,
        error: ApiService.extractError(e),
      );
    }
  }

  Future<bool> claimReward(int missionId) async {
    try {
      AppLogger.debug('💰 Claiming reward for mission $missionId');
      
      await ApiService.claimMissionReward(missionId);
      
      AppLogger.debug('✅ Reward claimed successfully');
      
      // Reload missions to update state
      await loadMissions();
      
      // Also refresh wallet, so user sees updated balance immediately
      try {
        await _ref.read(riderWalletProvider.notifier).loadWallet(silent: true);
        AppLogger.debug('✅ Wallet refreshed after reward claim');
      } catch (e) {
        AppLogger.warn('Could not refresh wallet after reward: $e');
      }
      
      return true;
    } catch (e) {
      AppLogger.error('❌ Error claiming reward', e);
      state = state.copyWith(
        error: ApiService.extractError(e),
      );
      return false;
    }
  }
}

final riderMissionProvider =
    StateNotifierProvider<RiderMissionNotifier, RiderMissionState>(
      (ref) => RiderMissionNotifier(ref),
    );
