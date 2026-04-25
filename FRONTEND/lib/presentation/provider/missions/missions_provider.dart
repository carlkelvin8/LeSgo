import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/missions/mission.dart';

class MissionsState {
  final List<Mission> missions;
  final bool isLoading;

  MissionsState({
    required this.missions,
    this.isLoading = false,
  });

  MissionsState copyWith({
    List<Mission>? missions,
    bool? isLoading,
  }) {
    return MissionsState(
      missions: missions ?? this.missions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MissionsNotifier extends StateNotifier<MissionsState> {
  MissionsNotifier()
      : super(MissionsState(
          missions: [
            Mission(
              id: '1',
              title: 'Book 1 LeSeat today',
              progress: 0,
              total: 1,
            ),
            Mission(
              id: '2',
              title: 'Refer 1 friend',
              progress: 0,
              total: 1,
            ),
            Mission(
              id: '3',
              title: 'Leave us a review',
              progress: 0,
              total: 1,
            ),
            Mission(
              id: '4',
              title: 'Like our FB page',
              progress: 0,
              total: 1,
            ),
            Mission(
              id: '5',
              title: 'Book 5 LeSride',
              progress: 0,
              total: 5,
            ),
          ],
        ));

  Future<void> refreshMissions() async {
    state = state.copyWith(isLoading: true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    state = state.copyWith(isLoading: false);
  }

  void updateProgress(String missionId, double newProgress) {
    final updatedMissions = state.missions.map((mission) {
      if (mission.id == missionId) {
        return Mission(
          id: mission.id,
          title: mission.title,
          progress: newProgress,
          total: mission.total,
        );
      }
      return mission;
    }).toList();

    state = state.copyWith(missions: updatedMissions);
  }
}

final missionsProvider =
    StateNotifierProvider<MissionsNotifier, MissionsState>((ref) {
  return MissionsNotifier();
});
