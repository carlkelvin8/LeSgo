import '../constants/api_constants.dart';
import '../../domain/entities/auth/registration_fee_status.dart';
import 'api_service.dart';

class RegistrationFeeCheckout {
  final String? checkoutUrl;
  final String? checkoutId;
  final String? paymongoReference;
  final double amount;
  final String? paymentStatus;
  final String? statusMessage;
  final bool reused;

  const RegistrationFeeCheckout({
    this.checkoutUrl,
    this.checkoutId,
    this.paymongoReference,
    this.amount = 0,
    this.paymentStatus,
    this.statusMessage,
    this.reused = false,
  });

  static RegistrationFeeCheckout fromRaw(dynamic raw) {
    final map = raw is Map
        ? Map<String, dynamic>.from(raw['data'] ?? raw)
        : <String, dynamic>{};

    double? parsedAmount;
    final amountRaw = map['amount'];
    if (amountRaw is num) {
      parsedAmount = amountRaw.toDouble();
    } else if (amountRaw is String) {
      parsedAmount = double.tryParse(amountRaw);
    }

    return RegistrationFeeCheckout(
      checkoutUrl: map['checkout_url']?.toString(),
      checkoutId: map['checkout_id']?.toString(),
      paymongoReference: map['paymongo_reference']?.toString(),
      amount: parsedAmount ?? (amountRaw is num ? amountRaw.toDouble() : 0),
      paymentStatus: map['payment_status']?.toString(),
      statusMessage: map['status_message']?.toString(),
      reused: map['reused'] == true,
    );
  }
}

class RegistrationFeeApi {
  RegistrationFeeApi._();

  static Future<RegistrationFeeStatus> fetchStatus() async {
    final response = await ApiService.dio.get(ApiConstants.registrationFeeStatus);
    final raw = response.data;
    final data = raw is Map ? (raw['data'] ?? raw) : raw;
    final status = RegistrationFeeStatus.fromJson(data);
    if (status == null) {
      throw Exception('Invalid registration fee status response');
    }
    return status;
  }

  static Future<RegistrationFeeCheckout> createCheckout() async {
    final response = await ApiService.dio.post(
      ApiConstants.registrationFeeCheckout,
    );
    return RegistrationFeeCheckout.fromRaw(response.data);
  }

  static Future<RegistrationFeeStatus> verifyPayment({
    String? checkoutId,
  }) async {
    final response = await ApiService.dio.post(
      ApiConstants.registrationFeeVerify,
      data: {
        if (checkoutId != null && checkoutId.isNotEmpty)
          'checkout_id': checkoutId,
      },
    );
    final raw = response.data;
    final data = raw is Map ? (raw['data'] ?? raw) : raw;
    final statusMap =
        data is Map ? (data['status'] ?? data) : data;
    final status = RegistrationFeeStatus.fromJson(statusMap);
    if (status == null) {
      throw Exception('Invalid payment verification response');
    }
    return status;
  }
}