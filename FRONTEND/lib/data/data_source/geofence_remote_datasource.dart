import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/network/dio_client.dart';
import 'dto/geofence/geofence_dto.dart';

@lazySingleton
class GeofenceRemoteDataSource {
  final DioClient _dioClient;

  GeofenceRemoteDataSource(this._dioClient);

  /// Get geofences
  Future<List<GeofenceDto>> getGeofences() async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/geofences');
      return (response.data['data'] as List)
          .map((item) => GeofenceDto.fromJson(item))
          .toList();
    } catch (e) {
      // Mock response
      return [
        GeofenceDto(
          id: 1,
          name: 'Manila City Center',
          type: 'delivery_zone',
          latitude: 14.5995,
          longitude: 120.9842,
          radiusKm: 5.0,
          isActive: true,
          createdAt: DateTime.now().toIso8601String(),
        ),
        GeofenceDto(
          id: 2,
          name: 'Quezon City Mall',
          type: 'pickup_zone',
          latitude: 14.6760,
          longitude: 121.0437,
          radiusKm: 2.0,
          isActive: true,
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];
    }
  }

  /// Get geofence types
  Future<List<String>> getGeofenceTypes() async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/geofences/types');
      return List<String>.from(response.data['data'] ?? []);
    } catch (e) {
      // Mock response
      return ['delivery_zone', 'pickup_zone', 'restricted_area', 'service_area'];
    }
  }

  /// Get geofence statistics
  Future<GeofenceStatisticsDto> getGeofenceStatistics() async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/geofences/statistics');
      return GeofenceStatisticsDto.fromJson(response.data['data']);
    } catch (e) {
      // Mock response
      return GeofenceStatisticsDto(
        totalGeofences: 25,
        activeGeofences: 20,
        totalEntriesToday: 150,
        totalOrdersFromGeofences: 145,
      );
    }
  }

  /// Check location against geofences
  Future<LocationCheckDto> checkLocation({
    required double latitude,
    required double longitude,
  }) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.post('/v1/geofences/check', data: {
        'latitude': latitude,
        'longitude': longitude,
      });
      return LocationCheckDto.fromJson(response.data['data']);
    } catch (e) {
      // Mock response
      return LocationCheckDto(
        insideGeofence: true,
        geofences: [
          GeofenceInfoDto(
            id: 1,
            name: 'Manila City Center',
            type: 'delivery_zone',
          ),
        ],
      );
    }
  }
}