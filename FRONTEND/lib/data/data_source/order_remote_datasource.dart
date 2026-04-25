import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/order/create_order_request_dto.dart';
import 'dto/order/orders_response_dto.dart';
import 'dto/order/estimate_request_dto.dart';
import 'dto/order/estimate_response_dto.dart';

@lazySingleton
class OrderRemoteDataSource {
  final DioClient _dioClient;

  OrderRemoteDataSource(this._dioClient);

  // Existing estimate method
  Future<EstimateResponseDto> getFareEstimate(
    EstimateRequestDto request,
  ) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.post(
        ApiConstants.orderEstimate,
        data: request.toJson(),
      );
      return EstimateResponseDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get fare estimate: $e');
    }
  }

  // NEW: List orders
  Future<OrdersResponseDto> getOrders({
    String? status,
    String? paymentStatus,
    int? serviceId,
    int perPage = 20,
  }) async {
    final dio = _dioClient.dio;
    try {
      final queryParams = <String, dynamic>{
        'per_page': perPage,
      };
      if (status != null) queryParams['status'] = status;
      if (paymentStatus != null) queryParams['payment_status'] = paymentStatus;
      if (serviceId != null) queryParams['service_id'] = serviceId;

      final response = await dio.get(
        ApiConstants.orders,
        queryParameters: queryParams,
      );
      return OrdersResponseDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get orders: $e');
    }
  }

  // NEW: Create order
  Future<OrderResponseDto> createOrder(CreateOrderRequestDto request) async {
    final dio = _dioClient.dio;
    try {
      final requestData = request.toJson();
      print('=== CREATE ORDER REQUEST ===');
      print(requestData);
      final response = await dio.post(
        ApiConstants.orders,
        data: requestData,
      );
      // API returns {"success": true, "message": "...", "data": {...}}
      // Map "data" to the expected structure
      final responseData = Map<String, dynamic>.from(response.data);
      return OrderResponseDto.fromJson(responseData);
    } on DioException catch (e) {
      print('=== CREATE ORDER ERROR ===');
      print('Status: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
      throw Exception('Failed to create order: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // NEW: Get order by ID
  Future<OrderResponseDto> getOrder(int id) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get(ApiConstants.orderById(id));
      return OrderResponseDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // NEW: Update order status
  Future<OrderResponseDto> updateOrderStatus({
    required int id,
    String? status,
    String? paymentStatus,
    String? cancelReason,
    int? actualDistanceM,
  }) async {
    final dio = _dioClient.dio;
    try {
      final data = <String, dynamic>{};
      if (status != null) data['status'] = status;
      if (paymentStatus != null) data['payment_status'] = paymentStatus;
      if (cancelReason != null) data['cancel_reason'] = cancelReason;
      if (actualDistanceM != null) data['actual_distance_m'] = actualDistanceM;

      final response = await dio.patch(
        ApiConstants.orderStatus(id),
        data: data,
      );
      return OrderResponseDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// POST /v1/orders/{id}/cancel
  Future<OrderResponseDto> cancelOrder(int orderId, String reason) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.post(
        '${ApiConstants.orderById(orderId)}/cancel',
        data: {'reason': reason},
      );
      return OrderResponseDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  /// POST /v1/orders/{id}/reorder
  Future<OrderResponseDto> reorderOrder(int orderId) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.post(
        '${ApiConstants.orderById(orderId)}/reorder',
      );
      return OrderResponseDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to reorder: $e');
    }
  }

  /// GET /v1/orders/{id}/receipt
  Future<OrderResponseDto> getOrderReceipt(int orderId) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get(ApiConstants.orderReceipt(orderId));
      return OrderResponseDto.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get order receipt: $e');
    }
  }
}
