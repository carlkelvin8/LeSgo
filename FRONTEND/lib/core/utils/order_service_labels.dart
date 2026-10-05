import '../../data/data_source/dto/order/order_dto.dart';

/// Display labels and icons for order services.
class OrderServiceLabels {
  OrderServiceLabels._();

  static String fromServiceId(int? serviceId) {
    switch (serviceId) {
      case 1:
        return 'LesGo';
      case 2:
        return 'LesRide';
      case 3:
        return 'LesEat';
      case 4:
        return 'LesBuy';
      case 5:
        return 'LesTransport';
      default:
        return 'Order';
    }
  }

  static String fromServiceType(String? serviceType) {
    if (serviceType == null || serviceType.trim().isEmpty) {
      return 'Order';
    }

    final normalized = serviceType.toLowerCase().replaceAll(' ', '');
    switch (normalized) {
      case 'lesgo':
        return 'LesGo';
      case 'lesride':
        return 'LesRide';
      case 'leseat':
        return 'LesEat';
      case 'lesbuy':
      case 'lesbuymanual':
        return 'LesBuy';
      case 'lestransport':
      case 'lesport':
        return 'LesTransport';
      default:
        if (serviceType.length <= 4) return serviceType.toUpperCase();
        return serviceType[0].toUpperCase() + serviceType.substring(1);
    }
  }

  static String labelForOrder(OrderDto order) {
    if (order.serviceType != null && order.serviceType!.trim().isNotEmpty) {
      return fromServiceType(order.serviceType);
    }
    return fromServiceId(order.serviceId);
  }

  static String conversationTitle({
    String? serviceName,
    int? serviceId,
    String? serviceType,
    required int orderId,
  }) {
    if (serviceName != null && serviceName.trim().isNotEmpty) {
      return '$serviceName Order #$orderId';
    }
    if (serviceType != null && serviceType.trim().isNotEmpty) {
      return '${fromServiceType(serviceType)} Order #$orderId';
    }
    if (serviceId != null) {
      return '${fromServiceId(serviceId)} Order #$orderId';
    }
    return 'Order #$orderId';
  }
}
