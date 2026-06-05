import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities/missions/mission.dart';
import '../../../data/data_source/missions_remote_datasource.dart';
import '../../../data/data_source/social_remote_datasource.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/api_error_mapper.dart';

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
  final MissionsRemoteDataSource _missionsDataSource =
      getIt<MissionsRemoteDataSource>();
  final SocialRemoteDataSource _socialDataSource =
      getIt<SocialRemoteDataSource>();

  MissionsNotifier()
      : super(MissionsState(
          missions: [],
          isLoading: true,
        )) {
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final response = await _missionsDataSource.getMissions();

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

      state = state.copyWith(
        missions: missions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        missions: [],
        isLoading: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not load missions. Pull to retry.',
          fallbackTl: 'Hindi ma-load ang missions. Subukan muli.',
        ),
      );
    }
  }

  Future<void> refreshMissions() async {
    await _loadMissions();
  }

  Future<void> claimMission(int missionId) async {
    try {
      final response = await _missionsDataSource.claimMission(missionId);

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

      state = state.copyWith(missions: updatedMissions, clearError: true);
    } catch (e) {
      state = state.copyWith(
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Failed to claim reward.',
          fallbackTl: 'Hindi ma-claim ang reward.',
        ),
      );
      rethrow;
    }
  }

  Future<void> performMissionAction(Mission mission) async {
    switch (mission.missionType) {
      case 'app_review':
        await launchUrl(
          Uri.parse(
            'https://play.google.com/store/apps/details?id=com.lezgo.app',
          ),
          mode: LaunchMode.externalApplication,
        );
        await _missionsDataSource.recordProgress(mission.id);
        break;
      case 'social_follow':
        await launchUrl(
          Uri.parse('https://www.facebook.com/lesgo'),
          mode: LaunchMode.externalApplication,
        );
        await _socialDataSource.confirmSocialFollow(platform: 'facebook');
        final share = await _socialDataSource.generateReferralShare(
          platform: 'facebook',
        );
        await Share.share(
          '${share.content}\n${share.shareUrl}',
          subject: 'Follow LeSGo',
        );
        await _missionsDataSource.recordProgress(mission.id);
        break;
      default:
        return;
    }
    await refreshMissions();
  }
}

final missionsProvider =
    StateNotifierProvider<MissionsNotifier, MissionsState>((ref) {
  return MissionsNotifier();
});
