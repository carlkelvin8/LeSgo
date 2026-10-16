import 'package:injectable/injectable.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'dto/gateway/invoice_response_dto.dart';
import 'dto/payment/invoice_request_dto.dart';
import 'dto/gateway/refund_request_dto.dart';
import 'dto/gateway/refund_response_dto.dart';
import 'dto/wallet/wallet_validation_dto.dart';

@lazySingleton
class PaymentGatewayRemoteDataSource {
  final DioClient _dioClient;

  PaymentGatewayRemoteDataSource(this._dioClient);

  /// Create a payment invoice
  Future<InvoiceResponseDto> createInvoice(InvoiceRequestDto request) async {
    final dio = _dioClient.dio;
    final response = await dio.post(
      '/v1/payment-gateway/invoices',
      data: request.toJson(),
    );
    return InvoiceResponseDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// Validate whether the current wallet balance can be used.
  Future<WalletValidationDto> validateWalletBalance() async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/payment-gateway/wallet/validate');
      return WalletValidationDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to validate wallet balance: $e');
    }
  }

  /// Get wallet threshold configuration.
  Future<WalletThresholdDto> getWalletThreshold() async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.get('/v1/payment-gateway/wallet/threshold');
      return WalletThresholdDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get wallet threshold: $e');
    }
  }

  /// Get invoice by ID
  Future<InvoiceResponseDto> getInvoice(String invoiceId) async {
    final dio = _dioClient.dio;
    final response = await dio.get('/v1/payment-gateway/invoices/$invoiceId');
    return InvoiceResponseDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// Compatibility alias for provider code.
  Future<InvoiceResponseDto> getInvoiceStatus(String invoiceId) {
    return getInvoice(invoiceId);
  }

  /// Request a refund
  Future<RefundResponseDto> requestRefund(RefundRequestDto request) async {
    final dio = _dioClient.dio;
    try {
      final response = await dio.post(
        ApiConstants.paymentGatewayRefunds,
        data: request.toJson(),
      );
      return RefundResponseDto.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to request refund: $e');
    }
  }
}
