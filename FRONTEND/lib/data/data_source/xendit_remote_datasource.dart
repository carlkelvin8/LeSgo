import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/xendit_config.dart';
import 'dto/xendit/xendit_invoice_dto.dart';

@lazySingleton
class XenditRemoteDataSource {
  late final Dio _dio;

  XenditRemoteDataSource() {
    final credentials = base64Encode(
      utf8.encode('${XenditConfig.secretKey}:'),
    );
    _dio = Dio(
      BaseOptions(
        baseUrl: XenditConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<XenditInvoiceDto> createTopUpInvoice({
    required double amount,
    required String description,
    String? externalId,
    /// Total amount to charge (wallet amount + fee). Defaults to [amount].
    double? chargeAmount,
  }) async {
    final charge = chargeAmount ?? amount;
    final id = externalId ?? 'lespay-topup-${const Uuid().v4()}';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v2/invoices',
        data: {
          'external_id': id,
          'amount': charge,
          'description': description,
          'currency': 'PHP',
          'invoice_duration': 86400,
          'success_redirect_url': XenditConfig.successRedirectUrl,
          'failure_redirect_url': XenditConfig.failureRedirectUrl,
        },
      );

      final data = response.data;
      if (data == null || data['id'] == null) {
        throw Exception('Invalid response from Xendit.');
      }
      final invoice = XenditInvoiceDto.fromJson(data);
      if (invoice.invoiceUrl == null || invoice.invoiceUrl!.isEmpty) {
        throw Exception('Xendit did not return a payment link.');
      }
      return invoice;
    } on DioException catch (e) {
      final message = _dioMessage(e);
      throw Exception(message ?? 'Could not connect to Xendit. Check your internet.');
    }
  }

  Future<XenditInvoiceDto> getInvoice(String invoiceId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v2/invoices/$invoiceId',
      );
      return XenditInvoiceDto.fromJson(response.data!);
    } on DioException catch (e) {
      final message = _dioMessage(e);
      throw Exception(message ?? 'Could not verify payment with Xendit.');
    }
  }

  String? _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return null;
  }
}
