import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/missions/mission.dart';
import '../../../data/data_source/missions_remote_datasource.dart';
import '../../../core/di/injection.dart';

class MissionsState {
  final List<Mission> missions;
  final bool isLoading;
  final String? error;

  MissionsState({
    required this.missions,
    this.isLoading = false,
    this.error,
  });

  MissionsState copyWith({
    List<Mission>? missions,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MissionsState(
      missions: missions ?? this.missions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MissionsNotifier extends StateNotifier<MissionsState> {
  final MissionsRemoteDataSource _missionsDataSource = getIt<MissionsRemoteDataSource>();

  MissionsNotifier()
      : super(MissionsState(
          missions: [],
          isLoading: true,
        )) {
    print('🔵 MissionsNotifier: Constructor called');
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    print('🔵 MissionsNotifier: _loadMissions called');
    
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      print('🔵 Missions: State updated to loading');
      
      print('🔵 Missions: Starting API call...');
      
      final response = await _missionsDataSource.getMissions();
      print('🟢 Missions: API call successful!');
      print('🟢 Missions: Got ${response.data.length} missions');
      
      final missions = response.data.map((missionDto) {
        return Mission(
          id: missionDto.id,
          userId: missionDto.userId,
          missionType: missionDto.missionType,
          title: missionDto.title,
          description: missionDto.description,
          currentProgress: missionDto.currentProgress,
          goalTarget: missionDto.goalTarget,
          isCompleted: missionDto.isCompleted,
          completedAt: missionDto.completedAt,
          rewardType: missionDto.rewardType,
          rewardValue: missionDto.rewardValue,
          rewardClaimed: missionDto.rewardClaimed,
          claimedAt: missionDto.claimedAt,
          missionDate: missionDto.missionDate,
        );
      }).toList();
      
      print('🟢 Missions: Mapped ${missions.length} missions');
      
      state = state.copyWith(
        missions: missions,
        isLoading: false,
      );
      
      print('🟢 Missions: State updated with ${missions.length} missions');
      
    } catch (e) {
      print('🔴 Missions: Error fetching missions - $e');
      print('🔴 Missions: Error type: ${e.runtimeType}');
      
      // Temporary fallback: Show static missions if API fails
      print('🔵 Missions: Using fallback static missions due to API error');
      final fallbackMissions = [
        Mission(
          id: 1,
          userId: 0,
          missionType: 'leseat_order',
          title: 'Book 1 LesEat today',
          description: 'Order food from any restaurant',
          currentProgress: 0,
          goalTarget: 1,
          isCompleted: false,
          completedAt: null,
          rewardType: 'voucher',
          rewardValue: 50.0,
          rewardClaimed: false,
          claimedAt: null,
          missionDate: DateTime.now().toIso8601String().split('T')[0],
        ),
        Mission(
          id: 2,
          userId: 0,
          missionType: 'friend_referral',
          title: 'Refer 1 friend',
          description: 'Invite a friend to join LesGo',
          currentProgress: 0,
          goalTarget: 1,
          isCompleted: false,
          completedAt: null,
          rewardType: 'voucher',
          rewardValue: 100.0,
          rewardClaimed: false,
          claimedAt: null,
          missionDate: DateTime.now().toIso8601String().split('T')[0],
        ),
        Mission(
          id: 3,
          userId: 0,
          missionType: 'app_review',
          title: 'Leave us a review',
          description: 'Rate our app on the store',
          currentProgress: 0,
          goalTarget: 1,
          isCompleted: false,
          completedAt: null,
          rewardType: 'voucher',
          rewardValue: 25.0,
          rewardClaimed: false,
          claimedAt: null,
          missionDate: DateTime.now().toIso8601String().split('T')[0],
        ),
        Mission(
          id: 4,
          userId: 0,
          missionType: 'social_follow',
          title: 'Like our FB page',
          description: 'Follow us on social media',
          currentProgress: 0,
          goalTarget: 1,
          isCompleted: false,
          completedAt: null,
          rewardType: 'voucher',
          rewardValue: 25.0,
          rewardClaimed: false,
          claimedAt: null,
          missionDate: DateTime.now().toIso8601String().split('T')[0],
        ),
        Mission(
          id: 5,
          userId: 0,
          missionType: 'lesride_orders',
          title: 'Book 5 LesRide',
          description: 'Complete 5 ride bookings',
          currentProgress: 0,
          goalTarget: 5,
          isCompleted: false,
          completedAt: null,
          rewardType: 'voucher',
          rewardValue: 200.0,
          rewardClaimed: false,
          claimedAt: null,
          missionDate: DateTime.now().toIso8601String().split('T')[0],
        ),
      ];
      
      state = state.copyWith(
        missions: fallbackMissions,
        isLoading: false,
        error: 'Using offline missions. API connection failed: ${e.toString()}',
      );
    }
  }

  Future<void> refreshMissions() async {
    print('🔵 Missions: Manual refresh triggered');
    await _loadMissions();
  }

  Future<void> claimMission(int missionId) async {
    try {
      print('🔵 Missions: Claiming mission $missionId');
      
      final response = await _missionsDataSource.claimMission(missionId);
      print('🟢 Missions: Mission claimed successfully');
      
      // Update the mission in the state
      final updatedMissions = state.missions.map((mission) {
        if (mission.id == missionId) {
          return Mission(
            id: response.data.id,
            userId: response.data.userId,
            missionType: response.data.missionType,
            title: response.data.title,
            description: response.data.description,
            currentProgress: response.data.currentProgress,
            goalTarget: response.data.goalTarget,
            isCompleted: response.data.isCompleted,
            completedAt: response.data.completedAt,
            rewardType: response.data.rewardType,
            rewardValue: response.data.rewardValue,
            rewardClaimed: response.data.rewardClaimed,
            claimedAt: response.data.claimedAt,
            missionDate: response.data.missionDate,
          );
        }
        return mission;
      }).toList();

      state = state.copyWith(missions: updatedMissions);
      
    } catch (e) {
      print('🔴 Missions: Error claiming mission - $e');
      state = state.copyWith(error: 'Failed to claim reward: $e');
      rethrow;
    }
  }

  void updateProgress(String missionId, double newProgress) {
    // This method is kept for backward compatibility but not used with real API
    print('⚠️ Missions: updateProgress called but using real API now');
  }
}

final missionsProvider =
    StateNotifierProvider<MissionsNotifier, MissionsState>((ref) {
  return MissionsNotifier();
});
