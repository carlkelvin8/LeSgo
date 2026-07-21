import '../../data/data_source/dto/order/order_dto.dart';
import '../../data/data_source/dto/order/orders_response_dto.dart';
import '../../data/data_source/dto/order/create_order_request_dto.dart';

/// Repository interface for order-related operations.
/// Providers should depend on this interface, not on OrderRemoteDataSource directly.
abstract class OrderRepository {
  /// Fetch all orders for the current user with optional filters.
  Future<OrdersResponseDto> getOrders({
    String? status,
    int page = 1,
    int perPage = 15,
  });

  /// Fetch a single order by ID.
  Future<OrderDto> getOrderById(int orderId);

  /// Create a new order.
  Future<OrderDto> createOrder(CreateOrderRequestDto request);

  /// Cancel an order.
  Future<void> cancelOrder(int orderId, {String? reason});

  /// Get active orders for the current user.
  Future<List<OrderDto>> getActiveOrders();

  /// Get order receipt.
  Future<Map<String, dynamic>> getOrderReceipt(int orderId);
}
