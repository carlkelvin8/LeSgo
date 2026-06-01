import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/missions/mission_dto.dart';

@injectable
class MissionsRemoteDataSource {
  final DioClient _dioClient;

  MissionsRemoteDataSource(this._dioClient);

  Future<MissionsResponseDto> getMissions() async {
    try {
      print('🔵 MissionsRemoteDataSource: Fetching missions...');
      
      final response = await _dioClient.dio.get(ApiConstants.missions);
      
      print('🟢 MissionsRemoteDataSource: Response received');
      print('🔍 Response data: ${response.data}');
      
      final missionsResponse = MissionsResponseDto.fromJson(response.data);
      
      print('🟢 MissionsRemoteDataSource: Parsed ${missionsResponse.data.length} missions');
      
      return missionsResponse;
    } catch (e) {
      print('🔴 MissionsRemoteDataSource: Error fetching missions - $e');
      if (e is DioException) {
        print('🔴 DioException details: ${e.response?.data}');
        print('🔴 Status code: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  Future<ClaimMissionResponseDto> claimMission(int missionId) async {
    try {
      print('🔵 MissionsRemoteDataSource: Claiming mission $missionId...');
      
      final response = await _dioClient.dio.post(
        ApiConstants.missionClaim(missionId),
      );
      
      print('🟢 MissionsRemoteDataSource: Mission claimed successfully');
      
      final claimResponse = ClaimMissionResponseDto.fromJson(response.data);
      
      return claimResponse;
    } catch (e) {
      print('🔴 MissionsRemoteDataSource: Error claiming mission - $e');
      if (e is DioException) {
        print('🔴 DioException details: ${e.response?.data}');
        print('🔴 Status code: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }
}