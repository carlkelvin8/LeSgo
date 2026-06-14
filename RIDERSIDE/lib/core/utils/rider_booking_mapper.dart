import '../../domain/entities/rider_booking.dart';
import '../../presentation/provider/main/riderside/rider_orders_provider.dart';
import 'booking_workflow.dart';

class RiderBookingMapper {
  RiderBookingMapper._();

  static RiderBooking fromOrder(
    RiderOrder order, {
    String? packageTier,
    double? riderCommissionRate,
    List<String>? proofOfDeliveryUrls,
    int? orderRating,
  }) {
    final category = BookingWorkflow.categoryFromServiceId(order.serviceId);
    final riderEarnings = order.earningsFor(
      packageTier: packageTier,
      riderCommissionRate: riderCommissionRate,
    );
    final customerName = order.dropoffContactName.trim().isNotEmpty
        ? order.dropoffContactName.trim()
        : 'Customer';
    final customerPhone = order.dropoffContactPhone.trim().isNotEmpty
        ? order.dropoffContactPhone.trim()
        : (order.pickupContactPhone.trim().isNotEmpty
            ? order.pickupContactPhone.trim()
            : null);

    final isFoodOrder =
        category == BookingCategory.lesEat || category == BookingCategory.lesBuy;

    return RiderBooking(
      id: order.id.toString(),
      serviceId: order.serviceId,
      restaurantName: _pickupLabel(order, category),
      customerName: customerName,
      address: order.dropoffAddress,
      pickupAddress: order.pickupAddress,
      deliveryAddress: order.dropoffAddress,
      distance: '${order.distanceKm.toStringAsFixed(1)} km',
      estimatedTime: _estimateTime(order.distanceKm),
      earnings:
          'Your earnings PHP ${riderEarnings.toStringAsFixed(2)}',
      paymentMethod: order.paymentMethod.toUpperCase(),
      items: order.parsedItems.isEmpty ? null : order.parsedItems,
      pickupLat: order.pickupLat,
      pickupLng: order.pickupLng,
      dropoffLat: order.dropoffLat,
      dropoffLng: order.dropoffLng,
      category: category,
      itemsSubtotal: isFoodOrder && order.itemsTotal > 0
          ? 'Items subtotal PHP ${order.itemsTotal.toStringAsFixed(2)}'
          : null,
      billingAmount:
          'Order total PHP ${order.displayTotalAmount.toStringAsFixed(2)}',
      deliveryFee: isFoodOrder
          ? 'Delivery fee PHP ${order.displayShippingFee.toStringAsFixed(2)}'
          : 'LesPay hold (shipping only) PHP ${order.walletDeductionAmount.toStringAsFixed(2)}',
      billingMethod: order.paymentMethod.toUpperCase(),
      currentStatus:
          BookingWorkflow.mapApiStatus(order.status, order.serviceId),
      proofOfDeliveryUrls: proofOfDeliveryUrls,
      customerPhone: customerPhone,
      orderRating: orderRating,
    );
  }

  static String _pickupLabel(RiderOrder order, BookingCategory category) {
    if (category == BookingCategory.lesRide) {
      return order.serviceName;
    }
    return order.pickupAddress;
  }

  static String _estimateTime(double distanceKm) {
    final minutes = ((distanceKm / 30) * 60).round();
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60}h ${minutes % 60}min';
  }
}
