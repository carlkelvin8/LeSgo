import 'package:injectable/injectable.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/distance/distance_dto.dart';

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
    final response = await dio.post(
      ApiConstants.distanceCalculate,
      data: {
        'from_lat': fromLat,
        'from_lng': fromLng,
        'to_lat': toLat,
        'to_lng': toLng,
      },
    );
    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    return DistanceCalculationDto(
      distanceKm: (data['distance_km'] as num).toDouble(),
      distanceM: (data['distance_m'] as num).toDouble(),
      unit: data['unit']?.toString() ?? 'km',
    );
  }

  /// Get overall distance statistics
  Future<OverallDistanceStatsDto> getOverallDistanceStats() async {
    final dio = _dioClient.dio;
    final response = await dio.get(ApiConstants.distanceOverall);
    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    final totalKm = (data['total_distance_km'] as num?)?.toDouble() ?? 0;
    final countOrders = (data['count_orders'] as num?)?.toInt() ?? 0;
    final averageKm = countOrders > 0 ? totalKm / countOrders : 0.0;

    return OverallDistanceStatsDto(
      totalDistanceKm: totalKm,
      totalOrders: countOrders,
      averageDistanceKm: double.parse(averageKm.toStringAsFixed(2)),
    );
  }
}
