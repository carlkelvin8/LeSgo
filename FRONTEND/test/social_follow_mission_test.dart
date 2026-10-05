import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lesgo/core/di/injection.dart';
import 'package:lesgo/data/data_source/dto/missions/mission_dto.dart';
import 'package:lesgo/data/data_source/missions_remote_datasource.dart';
import 'package:lesgo/domain/entities/missions/mission.dart';
import 'package:lesgo/presentation/provider/missions/missions_provider.dart';
import 'package:lesgo/presentation/widgets/missions/mission_card.dart';

class FakeMissionsSource implements MissionsRemoteDataSource {

  @override
  Future<MissionsResponseDto> getMissions() async => MissionsResponseDto(
    success: true,
    message: 'OK',
    data: [
      MissionDto(
        id: 1,
        userId: 42,
        missionType: 'social_follow',
        title: 'Follow FB page',
        currentProgress: 1,
        goalTarget: 1,
        isCompleted: true,
        completedAt: '2026-09-22T10:00:00Z',
        rewardType: 'voucher',
        rewardValue: 25,
        rewardClaimed: false,
        missionDate: '2026-09-22',
      ),
      MissionDto(
        id: 2,
        userId: 42,
        missionType: 'app_review',
        title: 'Review the app',
        currentProgress: 0,
        goalTarget: 1,
        isCompleted: false,
        rewardType: 'voucher',
        rewardValue: 25,
        rewardClaimed: false,
        missionDate: '2026-09-22',
      ),
    ],
  );

  @override
  Future<ClaimMissionResponseDto> claimMission(int missionId) async {
    throw StateError('A follow claim must never reach the API');
  }

  @override
  Future<void> recordProgress(int missionId) async {
    throw StateError('A follow must never record client-reported progress');
  }
}

void main() {
  late FakeMissionsSource source;

  setUp(() {
    source = FakeMissionsSource();
    getIt.registerSingleton<MissionsRemoteDataSource>(source);
  });

  tearDown(() async => getIt.reset());

  test('retired social follow missions are filtered from customer app', () async {
      final notifier = MissionsNotifier();
      addTearDown(notifier.dispose);
      await notifier.refreshMissions();

      expect(notifier.state.missions, hasLength(1));
      expect(notifier.state.missions.single.missionType, 'app_review');
  });

  testWidgets('mission card no longer renders the retired paused follow state', (
    tester,
  ) async {
    final mission = Mission(
      id: 1,
      userId: 42,
      missionType: 'social_follow',
      title: 'Follow FB page',
      currentProgress: 1,
      goalTarget: 1,
      isCompleted: true,
      rewardType: 'voucher',
      rewardValue: 25,
      rewardClaimed: false,
      missionDate: '2026-09-22',
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: MissionCard(mission: mission)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Paused'), findsNothing);
    expect(find.text('Claim'), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

