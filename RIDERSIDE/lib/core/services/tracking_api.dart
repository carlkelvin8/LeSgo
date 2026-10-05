import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../di/injection.dart';
import '../network/dio_client.dart';
import '../utils/app_logger.dart';

/// Driver tracking and location HTTP endpoints.
class TrackingApi {
  TrackingApi._();

  static Dio get _dio => getIt<DioClient>().dio;

  static Future<void> updateDriverLocation(
    int driverProfileId,
    double lat,
    double lng, {
    String status = 'online',
    int? orderId,
  }) async {
    try {
      await _dio.post(
        '/v1/tracking/driver/location',
        data: {
          'driver_id': driverProfileId,
          'latitude': lat,
          'longitude': lng,
          'status': status,
          if (orderId != null) 'order_id': orderId,
        },
      );
    } catch (e) {
      // Don't rethrow — location update failures should not block the rider UI.
      // The next location update will retry automatically.
      AppLogger.error('Error updating driver location (non-fatal)', e);
    }
  }

  static Future<void> updateDriverAvailability(
    int driverProfileId,
    bool isAvailable,
  ) async {
    try {
      await _dio.patch('/v1/drivers/$driverProfileId', data: {
        'is_available': isAvailable,
      });
    } catch (e) {
      AppLogger.error('Error updating driver availability', e);
      rethrow;
    }
  }

  /// Resolves the current user's driver profile on API versions that do not
  /// embed `driver_profile` in the login or `/auth/me` response.
  static Future<Map<String, dynamic>?> getMyDriverProfile(int userId) async {
    final res = await _dio.get('/v1/drivers');
    dynamic data = res.data;
    if (data is Map) data = data['data'] ?? data;
    if (data is Map) data = data['data'] ?? data;

    if (data is! List) return null;
    for (final item in data) {
      if (item is! Map) continue;
      final profile = Map<String, dynamic>.from(item);
      final rawUserId = profile['user_id'];
      final profileUserId = rawUserId is num
          ? rawUserId.toInt()
          : int.tryParse(rawUserId?.toString() ?? '');
      if (profileUserId == userId) return profile;
    }
    return null;
  }

  static Future<Map<String, dynamic>> submitDutyAttendance(
    int driverProfileId,
    XFile photo, {
    double? latitude,
    double? longitude,
  }) async {
    final bytes = await photo.readAsBytes();
    final formData = FormData.fromMap({
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'photo': MultipartFile.fromBytes(
        bytes,
        filename: photo.name.isNotEmpty ? photo.name : 'duty_attendance.jpg',
      ),
    });

    final res = await _dio.post(
      '/v1/drivers/$driverProfileId/duty-attendance',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = res.data['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return Map<String, dynamic>.from(res.data as Map? ?? {});
  }

  static Future<Map<String, dynamic>?> getLiveOrderTracking(int orderId) async {
    try {
      final res = await _dio.get('/v1/tracking/order/$orderId/live');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error getting live tracking', e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getOrderETA(int orderId) async {
    try {
      final res = await _dio.get('/v1/tracking/order/$orderId/eta');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error getting ETA', e);
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String travelMode = 'two_wheeler',
  }) async {
    try {
      final res = await _dio.get('/v1/tracking/route', queryParameters: {
        'origin_lat': originLat,
        'origin_lng': originLng,
        'dest_lat': destLat,
        'dest_lng': destLng,
        'travel_mode': travelMode,
      });
      return res.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error getting route', e);
      return null;
    }
  }
}
