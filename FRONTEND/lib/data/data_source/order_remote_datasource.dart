import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/services/order_snapshot_cache.dart';
import '../../core/utils/proof_image_utils.dart';
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

  /// Get fare estimate using nested format required by the API
  Future<double?> getFareEstimateRaw({
    required int serviceId,
    required int estimatedDistanceM,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.post(
        ApiConstants.orderEstimate,
        data: {
          'service_id': serviceId,
          'estimated_distance_m': estimatedDistanceM,
          'pickup': {'lat': pickupLat, 'lng': pickupLng},
          'dropoff': {'lat': dropoffLat, 'lng': dropoffLng},
        },
      );
      final data = response.data['data'];
      if (data != null) {
        final fare = data['estimated_fare'];
        if (fare is num) return fare.toDouble();
        if (fare is String) return double.tryParse(fare);
      }
      return null;
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

      print('🔵 OrderRemoteDataSource: Making API call to ${ApiConstants.orders}');
      print('🔵 OrderRemoteDataSource: Query params: $queryParams');
      print('🔵 OrderRemoteDataSource: Base URL: ${ApiConstants.baseUrl}');

      final response = await dio.get(
        ApiConstants.orders,
        queryParameters: queryParams,
      );

      print('🟢 OrderRemoteDataSource: API response status: ${response.statusCode}');
      print('🟢 OrderRemoteDataSource: Response data type: ${response.data.runtimeType}');

      if (response.data == null) {
        print('🔴 OrderRemoteDataSource: Response data is null');
        throw Exception('API returned null data');
      }

      if (response.data is! Map) {
        print('🔴 OrderRemoteDataSource: Response data is not a Map: ${response.data}');
        throw Exception('API returned invalid data format');
      }

      final responseMap = response.data as Map<String, dynamic>;
      print('🟢 OrderRemoteDataSource: Response keys: ${responseMap.keys.toList()}');

      if (!responseMap.containsKey('success')) {
        print('🔴 OrderRemoteDataSource: Response missing success field');
        throw Exception('API response missing success field');
      }

      if (!responseMap.containsKey('data')) {
        print('🔴 OrderRemoteDataSource: Response missing data field');
        throw Exception('API response missing data field');
      }

      // Workaround: Inject cached meta/items + resolve proof image URLs
      if (responseMap['data'] is List) {
        final List dataList = responseMap['data'];
        for (var i = 0; i < dataList.length; i++) {
          final item = dataList[i];
          if (item is Map<String, dynamic>) {
            final id = item['id'];
            if (id != null && id is int) {
              OrderSnapshotCache.enrichOrderJson(item, id);
            }
            dataList[i] = ProofImageUtils.normalizeOrderJson(item);
          }
        }
      }

      final result = OrdersResponseDto.fromJson(responseMap);
      print('🟢 OrderRemoteDataSource: Parsed ${result.data.length} orders');

      return result;
    } on DioException catch (dioError) {
      print('🔴 OrderRemoteDataSource: Dio error - ${dioError.type}');
      print('🔴 OrderRemoteDataSource: Dio message - ${dioError.message}');
      print('🔴 OrderRemoteDataSource: Dio response - ${dioError.response?.data}');
      print('🔴 OrderRemoteDataSource: Dio status code - ${dioError.response?.statusCode}');

      if (dioError.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (dioError.response?.statusCode == 403) {
        throw Exception('Access denied. Please check your permissions.');
      } else {
        throw Exception('Network error: ${dioError.message}');
      }
    } catch (e) {
      print('🔴 OrderRemoteDataSource: General error - $e');
      print('🔴 OrderRemoteDataSource: Error type: ${e.runtimeType}');
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
      final dto = OrderResponseDto.fromJson(responseData);
      final orderId = dto.data.id;

      OrderSnapshotCache.save(orderId, {
        'meta': requestData['meta'],
        'items': OrderSnapshotCache.itemsFromRequest(
          request.items?.map((e) => e.toJson()).toList(),
          orderId,
        ),
        'payment_method': request.paymentMethod,
        'request': requestData,
      });

      if (responseData['data'] is Map<String, dynamic>) {
        OrderSnapshotCache.enrichOrderJson(
          responseData['data'] as Map<String, dynamic>,
          orderId,
        );
      }

      return dto;
    } on DioException catch (e) {
      print('=== CREATE ORDER ERROR ===');
      print('Status: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
      // Extract a readable message from the backend response
      final responseData = e.response?.data;
      String errorMsg;
      if (responseData is Map) {
        errorMsg = (responseData['message'] as String?)?.isNotEmpty == true
            ? responseData['message'] as String
            : (responseData['error'] as String?)?.isNotEmpty == true
                ? responseData['error'] as String
                : e.message ?? 'Failed to create order';
      } else {
        errorMsg = e.message ?? 'Failed to create order';
      }
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Fetch proof-of-delivery image URLs without requiring full [OrderDto] parse.
  Future<List<String>> fetchProofImages(int id) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get(ApiConstants.orderById(id));
      final body = response.data;
      if (body is! Map) return [];

      final data = body['data'];
      if (data is! Map) return [];

      final orderJson = ProofImageUtils.normalizeOrderJson(
        Map<String, dynamic>.from(data),
      );
      return ProofImageUtils.fromOrderMap(orderJson);
    } catch (e) {
      print('Failed to fetch proof images for order $id: $e');
      return [];
    }
  }

  // NEW: Get order by ID
  Future<OrderResponseDto> getOrder(int id) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get(ApiConstants.orderById(id));
      final responseData = Map<String, dynamic>.from(response.data);

      if (responseData['data'] is Map<String, dynamic>) {
        final data = Map<String, dynamic>.from(responseData['data'] as Map);
        OrderSnapshotCache.enrichOrderJson(data, id);
        responseData['data'] = ProofImageUtils.normalizeOrderJson(data);
      }

      return OrderResponseDto.fromJson(responseData);
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
      final responseData = Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is Map<String, dynamic>) {
        OrderSnapshotCache.enrichOrderJson(
          responseData['data'] as Map<String, dynamic>,
          id,
        );
      }

      return OrderResponseDto.fromJson(responseData);
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String errorMsg;
      if (responseData is Map) {
        errorMsg = (responseData['message'] as String?)?.isNotEmpty == true
            ? responseData['message'] as String
            : (responseData['error'] as String?)?.isNotEmpty == true
                ? responseData['error'] as String
                : e.message ?? 'Failed to update order status';
      } else {
        errorMsg = e.message ?? 'Failed to update order status';
      }
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Cancel order via PATCH /v1/orders/{id}/status with status=cancelled
  Future<OrderResponseDto> cancelOrder(int orderId, String reason) async {
    return updateOrderStatus(
      id: orderId,
      status: 'cancelled',
      cancelReason: reason,
    );
  }

  /// POST /v1/orders/{id}/reorder
  Future<OrderResponseDto> reorderOrder(int orderId) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.post(
        ApiConstants.orderReorder(orderId),
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
