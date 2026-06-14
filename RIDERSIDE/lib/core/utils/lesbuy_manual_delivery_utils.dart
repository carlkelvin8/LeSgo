class LesbuyManualDeliveryUtils {
  LesbuyManualDeliveryUtils._();

  static bool isManualLesbuyOrder(Map<String, dynamic>? orderData) {
    if (orderData == null) return false;
    final meta = orderData['meta'];
    if (meta is Map) {
      final map = Map<String, dynamic>.from(meta);
      if (map['delivery_fee_uncertain'] == true) return true;
      if (map['order_value_uncertain'] == true) return true;
      if (map['minimum_order_exempt'] == true) return true;
      final type = map['order_type']?.toString().toLowerCase();
      if (type == 'lesbuy_manual') return true;
    }
    final serviceId = orderData['service_id'];
    if (serviceId == 4 || serviceId == '4') {
      final notes = orderData['notes']?.toString().toLowerCase() ?? '';
      if (notes.contains('manual lesbuy')) return true;
    }
    return false;
  }

  static bool needsFirstItemPickupLocation(Map<String, dynamic>? orderData) {
    if (!isManualLesbuyOrder(orderData)) return false;
    final pickupLat = _toDouble(orderData?['pickup_lat']);
    final pickupLng = _toDouble(orderData?['pickup_lng']);
    return pickupLat == 0 && pickupLng == 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
