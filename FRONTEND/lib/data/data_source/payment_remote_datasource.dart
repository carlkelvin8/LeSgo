import 'package:injectable/injectable.dart';
import '../../core/network/dio_client.dart';
import 'dto/payment/payment_response_dto.dart';
import 'dto/payment/payments_response_dto.dart';
import 'dto/payment/create_payment_request_dto.dart';

@lazySingleton
class PaymentRemoteDataSource {
  final DioClient _dioClient;

  PaymentRemoteDataSource(this._dioClient);

  /// Get all payments for the authenticated user
  Future<PaymentsResponseDto> getPayments({
    String? status,
    int? orderId,
    int perPage = 20,
  }) async {
    final dio = _dioClient.dio;
    try {
      final queryParams = <String, dynamic>{
        'per_page': perPage,
      };
      if (status != null) queryParams['status'] = status;
      if (orderId != null) queryParams['order_id'] = orderId;

      final response = await dio.get(
        '/v1/payments',
        queryParameters: queryParams,
      );
      return PaymentsResponseDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get payments: $e');
    }
  }

  /// Get a single payment by ID
  Future<PaymentResponseDto> getPayment(int id) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/payments/$id');
      return PaymentResponseDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get payment: $e');
    }
  }

  /// Create a new payment
  Future<PaymentResponseDto> createPayment(CreatePaymentRequestDto request) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.post(
        '/v1/payments',
        data: request.toJson(),
      );
      return PaymentResponseDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }
}
