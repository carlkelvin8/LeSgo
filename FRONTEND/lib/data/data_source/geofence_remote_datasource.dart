import 'package:injectable/injectable.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/geofence/geofence_dto.dart';

@lazySingleton
class GeofenceRemoteDataSource {
  final DioClient _dioClient;

  GeofenceRemoteDataSource(this._dioClient);

  Future<List<GeofenceDto>> getGeofences() async {
    final response = await _dioClient.dio.get('/v1/geofences');
    return (response.data['data'] as List)
        .map((item) => GeofenceDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> getGeofenceTypes() async {
    final response = await _dioClient.dio.get('/v1/geofences/types');
    return List<String>.from(response.data['data'] ?? []);
  }

  Future<GeofenceStatisticsDto> getGeofenceStatistics() async {
    final response = await _dioClient.dio.get('/v1/geofences/statistics');
    return GeofenceStatisticsDto.fromJson(response.data['data']);
  }

  Future<LocationCheckDto> checkLocation({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dioClient.dio.post(
      ApiConstants.geofenceCheck,
      data: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return LocationCheckDto.fromJson(response.data['data']);
  }
}
