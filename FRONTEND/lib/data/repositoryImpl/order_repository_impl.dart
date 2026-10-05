import 'package:injectable/injectable.dart';

import '../../domain/repository/order_repository.dart';
import '../data_source/order_remote_datasource.dart';
import '../data_source/dto/order/order_dto.dart';
import '../data_source/dto/order/orders_response_dto.dart';
import '../data_source/dto/order/create_order_request_dto.dart';

/// Implementation of [OrderRepository] that delegates to the remote datasource.
/// This layer exists to:
/// 1. Decouple providers from the datasource (testability)
/// 2. Add caching, offline support, or data transformation in the future
/// 3. Allow swapping implementations without changing provider code
@LazySingleton(as: OrderRepository)
class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;

  OrderRepositoryImpl(this._remoteDataSource);

  @override
  Future<OrdersResponseDto> getOrders({
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    return await _remoteDataSource.getOrders(
      status: status,
      page: page,
      perPage: perPage,
    );
  }

  @override
  Future<OrderDto> getOrderById(int orderId) async {
    final response = await _remoteDataSource.getOrder(orderId);
    return response.data;
  }

  @override
  Future<OrderDto> createOrder(CreateOrderRequestDto request) async {
    final response = await _remoteDataSource.createOrder(request);
    return response.data;
  }

  @override
  Future<void> cancelOrder(int orderId, {String? reason}) async {
    await _remoteDataSource.cancelOrder(orderId, reason ?? 'Cancelled by user');
  }

  @override
  Future<List<OrderDto>> getActiveOrders() async {
    final response = await _remoteDataSource.getOrders(
      status: 'active',
      perPage: 50,
    );
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getOrderReceipt(int orderId) async {
    final response = await _remoteDataSource.getOrderReceipt(orderId);
    return response.toJson();
  }
}
