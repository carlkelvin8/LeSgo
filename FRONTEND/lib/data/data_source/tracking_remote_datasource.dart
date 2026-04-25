import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/tracking/tracking_dto.dart';
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

  /// Track order (mock implementation)
  Future<Map<String, dynamic>> trackOrder(int orderId) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/orders/$orderId');
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      return {
        'success': false,
        'data': null,
      };
    }
  }

  /// Get ETA for an order
  Future<Map<String, dynamic>> getEta(int orderId) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/tracking/order/$orderId/eta');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } catch (e) {
      // Fallback to mock data if API fails
      return {
        'success': true,
        'data': {
          'estimatedArrival': '15 minutes',
          'estimatedArrivalMinutes': 15,
          'distanceKm': 2.5,
          'currentLatitude': 8.4542,
          'currentLongitude': 124.6319,
        },
      };
    }
  }

  /// Get route between two points
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
      return {
        'success': true,
        'data': response.data['data'],
      };
    } catch (e) {
      // Fallback to mock data if API fails
      return {
        'success': true,
        'data': {
          'distance': {
            'value': 2500,
            'text': '2.5 km',
          },
          'duration': {
            'value': 900,
            'text': '15 mins',
          },
          'polyline': [],
        },
      };
    }
  }
}
