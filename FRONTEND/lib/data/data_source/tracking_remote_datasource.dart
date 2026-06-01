import 'package:injectable/injectable.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/tracking/tracking_response_dto.dart';
@lazySingleton
class TrackingRemoteDataSource {
  final DioClient _dioClient;

  TrackingRemoteDataSource(this._dioClient);

  /// Get tracking information for an order
  Future<TrackingResponseDto> getOrderTracking(int orderId) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/orders/$orderId/tracking');
      return TrackingResponseDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get order tracking: $e');
    }
  }

  /// Get driver location for an order
  Future<TrackingResponseDto> getDriverLocation(int orderId) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/orders/$orderId/driver-location');
      return TrackingResponseDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get driver location: $e');
    }
  }

  /// Lightweight order fetch for tracking screens.
  Future<Map<String, dynamic>> trackOrder(int orderId) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get(ApiConstants.orderById(orderId));
      final body = response.data as Map<String, dynamic>;
      return {'success': true, 'data': body['data'] ?? body};
    } catch (e) {
      return {'success': false, 'data': null, 'error': e.toString()};
    }
  }

  /// GET /v1/tracking/order/{id}/eta — no mock fallback on failure.
  Future<Map<String, dynamic>> getEta(int orderId) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/tracking/order/$orderId/eta');
      final body = response.data as Map<String, dynamic>;
      return {
        'success': body['success'] ?? true,
        'data': body['data'],
      };
    } catch (e) {
      return {'success': false, 'data': null};
    }
  }

  /// GET /v1/tracking/route — no mock fallback on failure.
  Future<Map<String, dynamic>> getRoute(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get(
        '/v1/tracking/route',
        queryParameters: {
          'origin_lat': originLat,
          'origin_lng': originLng,
          'dest_lat': destLat,
          'dest_lng': destLng,
        },
      );
      final body = response.data as Map<String, dynamic>;
      return {
        'success': body['success'] ?? true,
        'data': body['data'],
      };
    } catch (e) {
      return {'success': false, 'data': null};
    }
  }

  /// Parses ETA payload into display strings + optional driver coordinates.
  static ({
    String? eta,
    String? distance,
    double? driverLat,
    double? driverLng,
  }) parseEtaPayload(Map<String, dynamic>? data) {
    if (data == null) {
      return (eta: null, distance: null, driverLat: null, driverLng: null);
    }

    String? eta;
    if (data['estimated_arrival'] != null) {
      eta = data['estimated_arrival'].toString();
    } else if (data['estimatedArrival'] != null) {
      eta = data['estimatedArrival'].toString();
    } else if (data['estimatedArrivalMinutes'] != null) {
      final minutes = data['estimatedArrivalMinutes'] as num;
      eta = '${minutes.round()} min';
    } else if (data['minutes_remaining'] != null) {
      final minutes = data['minutes_remaining'] as num;
      eta = '${minutes.round()} min';
    }

    String? distance;
    if (data['distanceKm'] != null) {
      final distKm = data['distanceKm'] as num;
      distance = '${distKm.toStringAsFixed(1)} km';
    } else if (data['distance_remaining_m'] != null) {
      final distM = data['distance_remaining_m'] as num;
      distance = '${(distM / 1000).toStringAsFixed(1)} km';
    }

    final driverLat = _parseCoord(
      data['current_latitude'] ?? data['currentLatitude'],
    );
    final driverLng = _parseCoord(
      data['current_longitude'] ?? data['currentLongitude'],
    );

    return (
      eta: eta,
      distance: distance,
      driverLat: driverLat,
      driverLng: driverLng,
    );
  }

  static double? _parseCoord(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
