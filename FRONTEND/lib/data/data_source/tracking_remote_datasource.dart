import 'package:injectable/injectable.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/driver_display_utils.dart';
import 'dto/tracking/tracking_response_dto.dart';
import 'dto/tracking/tracking_dto.dart';

@lazySingleton
class TrackingRemoteDataSource {
  final DioClient _dioClient;

  TrackingRemoteDataSource(this._dioClient);

  /// Get tracking information for an order
  Future<TrackingResponseDto> getOrderTracking(int orderId) async {
    final dio = _dioClient.dio;
    final response = await dio.get(ApiConstants.orderTracking(orderId));
    final body = response.data as Map<String, dynamic>;
    final payload = Map<String, dynamic>.from(body['data'] as Map);
    final order = Map<String, dynamic>.from(
      (payload['order'] ?? payload) as Map,
    );
    final etaDetails = payload['eta_details'] as Map<String, dynamic>?;

    return TrackingResponseDto(
      success: body['success'] == true,
      data: _mapOrderToTrackingDto(
        order,
        currentStatus: payload['current_status']?.toString(),
        etaDetails: etaDetails,
      ),
    );
  }

  /// Get driver location for an order
  Future<TrackingResponseDto> getDriverLocation(int orderId) async {
    final dio = _dioClient.dio;
    final response = await dio.get(ApiConstants.orderDriverLocation(orderId));
    final body = response.data as Map<String, dynamic>;
    final location = Map<String, dynamic>.from(body['data'] as Map);

    return TrackingResponseDto(
      success: body['success'] == true,
      data: TrackingDto(
        orderId: orderId,
        driverId: null,
        currentLat: _parseDouble(location['latitude']),
        currentLng: _parseDouble(location['longitude']),
        status: 'in_transit',
        estimatedArrival: null,
        distanceRemainingM: null,
        pickupLatitude: 0,
        pickupLongitude: 0,
        dropoffLatitude: 0,
        dropoffLongitude: 0,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: location['updated_at']?.toString() ??
            DateTime.now().toIso8601String(),
      ),
    );
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

  /// GET /v1/tracking/order/{id}/live — canonical live tracking payload.
  Future<Map<String, dynamic>?> getLiveTracking(int orderId) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get(ApiConstants.trackingLive(orderId));
      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) return null;
      final data = body['data'];
      if (data is! Map) return null;
      final map = Map<String, dynamic>.from(data);

      final coords = _extractDriverCoordinates(map);
      final status = map['current_status'] ??
          map['status'] ??
          (map['order'] is Map
              ? (map['order'] as Map)['status']?.toString()
              : null);

      return {
        'status': status,
        'driver_lat': coords.$1,
        'driver_lng': coords.$2,
        'eta_minutes': map['eta_minutes'],
        'distance_to_destination_km': map['distance_to_destination_km'],
      };
    } catch (_) {
      return null;
    }
  }

  /// Resolves driver coordinates from backend live-tracking shapes.
  (double?, double?) _extractDriverCoordinates(Map<String, dynamic> map) {
    double? driverLat;
    double? driverLng;

    final driverLocation = map['driver_location'] ?? map['driverLocation'];
    if (driverLocation is Map) {
      driverLat = _parseDouble(driverLocation['latitude']);
      driverLng = _parseDouble(driverLocation['longitude']);
    }

    if (driverLat != null && driverLng != null) {
      return (driverLat, driverLng);
    }

    final order = map['order'] is Map
        ? Map<String, dynamic>.from(map['order'] as Map)
        : map;
    final driver = order['driver_profile'] ?? order['driverProfile'];
    if (driver is Map) {
      driverLat ??=
          _parseDouble(driver['last_latitude'] ?? driver['lastLatitude']);
      driverLng ??=
          _parseDouble(driver['last_longitude'] ?? driver['lastLongitude']);
    }

    final driverBlock = map['driver'];
    if (driverBlock is Map) {
      driverLat ??= _parseDouble(
        driverBlock['latitude'] ??
            driverBlock['last_latitude'] ??
            driverBlock['lastLatitude'],
      );
      driverLng ??= _parseDouble(
        driverBlock['longitude'] ??
            driverBlock['last_longitude'] ??
            driverBlock['lastLongitude'],
      );
    }

    return (driverLat, driverLng);
  }

  /// GET /v1/tracking/order/{id}/eta — no mock fallback on failure.
  Future<Map<String, dynamic>> getEta(int orderId) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get(ApiConstants.trackingEta(orderId));
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
        ApiConstants.trackingRoute,
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

  TrackingDto _mapOrderToTrackingDto(
    Map<String, dynamic> order, {
    String? currentStatus,
    Map<String, dynamic>? etaDetails,
  }) {
    final driverProfile = order['driver_profile'] ?? order['driverProfile'];
    Map<String, dynamic>? driverMap;
    if (driverProfile is Map) {
      driverMap = Map<String, dynamic>.from(driverProfile);
    }

    DriverDto? driver;
    final displayInfo = DriverInfo.fromDriverProfileMap(driverMap);
    if (displayInfo != null) {
      driver = DriverDto(
        id: ((driverMap?['user_id'] ?? driverMap?['id'] ?? 0) as num).toInt(),
        name: displayInfo.name,
        phone: displayInfo.phone,
        vehicleNumber: displayInfo.vehicleNumber,
        vehicleType: displayInfo.vehicleType ?? order['vehicle_type']?.toString(),
        photoUrl: displayInfo.photoUrl,
        rating: displayInfo.rating,
      );
    }

    return TrackingDto(
      orderId: (order['id'] as num).toInt(),
      driverId: order['driver_id'] as int?,
      currentLat: _parseDouble(
        driverMap?['last_latitude'] ?? driverMap?['lastLatitude'],
      ),
      currentLng: _parseDouble(
        driverMap?['last_longitude'] ?? driverMap?['lastLongitude'],
      ),
      status: currentStatus ?? order['status']?.toString() ?? 'pending',
      estimatedArrival: etaDetails?['estimated_arrival']?.toString(),
      distanceRemainingM: etaDetails?['distance_remaining_m'] as int?,
      pickupLatitude: _parseDouble(order['pickup_lat']) ?? 0,
      pickupLongitude: _parseDouble(order['pickup_lng']) ?? 0,
      dropoffLatitude: _parseDouble(order['dropoff_lat']) ?? 0,
      dropoffLongitude: _parseDouble(order['dropoff_lng']) ?? 0,
      createdAt: order['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      acceptedAt: order['accepted_at']?.toString(),
      pickedUpAt: order['picked_up_at']?.toString(),
      inTransitAt: order['in_transit_at']?.toString(),
      completedAt: order['completed_at']?.toString(),
      cancelledAt: order['cancelled_at']?.toString(),
      updatedAt: order['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
      driver: driver,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
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

    final driverLat = _parseDouble(
      data['current_latitude'] ?? data['currentLatitude'],
    );
    final driverLng = _parseDouble(
      data['current_longitude'] ?? data['currentLongitude'],
    );

    return (
      eta: eta,
      distance: distance,
      driverLat: driverLat,
      driverLng: driverLng,
    );
  }
}
