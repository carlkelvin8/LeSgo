import '../../data/data_source/dto/tracking/tracking_dto.dart';

/// Repository interface for order tracking operations.
abstract class TrackingRepository {
  /// Get live tracking data for an order.
  Future<TrackingDto> getOrderTracking(int orderId);

  /// Get driver location for an order.
  Future<Map<String, dynamic>> getDriverLocation(int orderId);

  /// Get ETA for an order.
  Future<Map<String, dynamic>> getOrderEta(int orderId);
}
