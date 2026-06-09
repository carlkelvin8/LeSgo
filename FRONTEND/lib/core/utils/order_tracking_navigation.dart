import 'package:flutter/material.dart';

import '../../data/data_source/dto/order/order_dto.dart';
import '../../presentation/screens/main/booking/leseat/leseat_order_tracking_screen.dart';
import '../../presentation/screens/main/booking/lesbuy/lesbuy_order_tracking_screen.dart';
import '../../presentation/screens/main/booking/lesgo/lesgo_order_tracking_screen.dart';
import 'order_service_labels.dart';

class OrderTrackingNavigation {
  OrderTrackingNavigation._();

  static Map<String, dynamic> buildOrderData(OrderDto order) {
    final items = order.effectiveItems;
    double itemsTotal = 0.0;
    final itemMaps = <Map<String, dynamic>>[];

    for (final item in items) {
      final price = item.actualPrice ?? item.estimatedPrice ?? 0.0;
      itemsTotal += price * item.quantity;
      itemMaps.add({
        'name': item.name,
        'price': price,
        'quantity': item.quantity,
        'total': price * item.quantity,
      });
    }

    final total = order.effectiveTotalAmount;
    final deliveryFee = total > itemsTotal ? total - itemsTotal : 0.0;

    return {
      'id': order.id,
      'status': order.status,
      'estimated_fare': order.estimatedFare,
      'actual_fare': order.actualFare ?? order.estimatedFare,
      'pickup_address': order.pickupAddress,
      'dropoff_address': order.dropoffAddress,
      'restaurantName': order.serviceId == 3 ? order.pickupAddress : null,
      'baseFee': order.estimatedFare > 0 ? 40.0 : 0.0,
      'distanceFee':
          order.estimatedFare > 40.0 ? order.estimatedFare - 40.0 : 0.0,
      'total': total,
      'subtotal': itemsTotal,
      'deliveryFee': deliveryFee,
      'paymentMethod': order.paymentMethod,
      'items': itemMaps,
    };
  }

  static void openTracking(BuildContext context, OrderDto order) {
    final orderData = buildOrderData(order);
    final orderId = order.id.toString();
    final serviceLabel = OrderServiceLabels.labelForOrder(order);

    switch (order.serviceId) {
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LeseatOrderTrackingScreen(
              orderId: orderId,
              orderType: 'LesEat',
              orderData: orderData,
            ),
          ),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LesbuyOrderTrackingScreen(
              orderId: orderId,
              orderType: 'LesBuy',
              orderData: orderData,
            ),
          ),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LesgoOrderTrackingScreen(
              orderId: orderId,
              orderType: serviceLabel,
              orderData: orderData,
            ),
          ),
        );
    }
  }
}
