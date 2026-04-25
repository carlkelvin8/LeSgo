import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/network/dio_client.dart';
import 'dto/distance/distance_dto.dart';
import 'dart:math' as math;

@lazySingleton
class DistanceRemoteDataSource {
  final DioClient _dioClient;

  DistanceRemoteDataSource(this._dioClient);

  /// Calculate distance between two points
  Future<DistanceCalculationDto> calculateDistance({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.post('/v1/distance/calculate', data: {
        'from_lat': fromLat,
        'from_lng': fromLng,
        'to_lat': toLat,
        'to_lng': toLng,
      });
      return DistanceCalculationDto.fromJson(response.data['data']);
    } catch (e) {
      // Mock response - calculate approximate distance
      final distance = _calculateHaversineDistance(fromLat, fromLng, toLat, toLng);
      return DistanceCalculationDto(
        distanceKm: distance,
        distanceM: distance * 1000,
        unit: 'km',
      );
    }
  }

  /// Get overall distance statistics
  Future<OverallDistanceStatsDto> getOverallDistanceStats() async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/distance/statistics');
      return OverallDistanceStatsDto.fromJson(response.data['data']);
    } catch (e) {
      // Mock response
      return OverallDistanceStatsDto(
        totalDistanceKm: 15420.5,
        totalOrders: 1250,
        averageDistanceKm: 12.3,
      );
    }
  }

  /// Calculate Haversine distance between two points (mock implementation)
  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) * 
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}