import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/gateway/invoice_dto.dart';
import 'dto/gateway/invoice_response_dto.dart';
import 'dto/gateway/create_invoice_request_dto.dart';
import 'dto/gateway/refund_request_dto.dart';
import 'dto/gateway/refund_response_dto.dart';

@lazySingleton
class PaymentGatewayRemoteDataSource {
  final DioClient _dioClient;

  PaymentGatewayRemoteDataSource(this._dioClient);

  /// Create a payment invoice
  Future<InvoiceResponseDto> createInvoice(CreateInvoiceRequestDto request) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.post(
        '/v1/payment-gateway/invoices',
        data: request.toJson(),
      );
      return InvoiceResponseDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create invoice: $e');
    }
  }

  /// Get invoice by ID
  Future<InvoiceResponseDto> getInvoice(String invoiceId) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/payment-gateway/invoices/$invoiceId');
      return InvoiceResponseDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get invoice: $e');
    }
  }

  /// Request a refund
  Future<RefundResponseDto> requestRefund(RefundRequestDto request) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.post(
        '/v1/payment-gateway/refunds',
        data: request.toJson(),
      );
      return RefundResponseDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to request refund: $e');
    }
  }
}
