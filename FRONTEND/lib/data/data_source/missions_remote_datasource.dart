import 'package:injectable/injectable.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/missions/mission_dto.dart';

@injectable
class MissionsRemoteDataSource {
  final DioClient _dioClient;

  MissionsRemoteDataSource(this._dioClient);

  Future<MissionsResponseDto> getMissions() async {
    final response = await _dioClient.dio.get(ApiConstants.missions);
    return MissionsResponseDto.fromJson(response.data);
  }

  Future<ClaimMissionResponseDto> claimMission(int missionId) async {
    final response = await _dioClient.dio.post(
      ApiConstants.missionClaim(missionId),
    );
    return ClaimMissionResponseDto.fromJson(response.data);
  }

  Future<void> recordProgress(int missionId) async {
    await _dioClient.dio.post(ApiConstants.missionProgress(missionId));
  }
}
