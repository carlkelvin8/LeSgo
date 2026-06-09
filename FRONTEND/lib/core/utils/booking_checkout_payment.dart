import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/injection.dart';
import '../../core/utils/api_error_mapper.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../data/data_source/order_remote_datasource.dart';
import '../../presentation/provider/main/lespay/lespay_provider.dart';
import '../../presentation/provider/main/payment_gateway/payment_gateway_provider.dart';
import '../../presentation/screens/main/booking/order_digital_payment_screen.dart';
import 'lespay_order_payment.dart';

/// Card / gateway checkout — paid via payment gateway before continuing.
const digitalPaymentMethods = {'card', 'xendit'};

bool isDigitalPaymentMethod(String method) =>
    digitalPaymentMethods.contains(method.toLowerCase());

bool isWalletPaymentMethod(String method) =>
    method.toLowerCase() == 'wallet';

/// Validates LesPay balance before placing a wallet order.
Future<bool> validateWalletBalanceForOrder(
  dynamic ref, {
  required double amount,
  required String paymentMethod,
  BuildContext? context,
}) async {
  if (!isWalletPaymentMethod(paymentMethod)) return true;

  await ref.read(lespayProvider.notifier).refreshBalance();
  final balance = ref.read(lespayProvider).balance;
  if (balance >= amount) return true;

  if (context != null && context.mounted) {
    SnackBarUtils.showError(
      context,
      'Insufficient LesPay balance. Top up or choose Cash on Delivery.',
    );
  }
  return false;
}

/// After [createOrder] succeeds: wallet debit sync, digital checkout, or cash pass-through.
/// Returns `true` when the booking may continue to tracking / confirmation.
Future<bool> completeBookingPayment({
  required BuildContext context,
  required dynamic ref,
  required int orderId,
  required double amount,
  required String paymentMethod,
  required String serviceLabel,
}) async {
  final method = paymentMethod.toLowerCase();

  if (isWalletPaymentMethod(method)) {
    await applyLesPayWalletDeduction(
      ref,
      paymentMethod: method,
      amount: amount,
    );
    return true;
  }

  if (!isDigitalPaymentMethod(method)) {
    return true;
  }

  if (amount <= 0) {
    SnackBarUtils.showError(context, 'Invalid order amount for digital payment.');
    return false;
  }

  final gateway = ref.read(paymentGatewayProvider.notifier);
  final invoice = await gateway.createOrderPaymentInvoice(
    orderId: orderId,
    amount: amount,
    paymentMethod: method,
    context: context,
  );

  if (invoice == null ||
      invoice.invoiceUrl == null ||
      invoice.invoiceUrl!.isEmpty) {
    if (context.mounted) {
      SnackBarUtils.showError(
        context,
        'Could not start digital payment. Try Cash or LesPay wallet.',
      );
    }
    await _markPaymentFailed(orderId);
    return false;
  }

  if (!context.mounted) return false;

  final paid = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => OrderDigitalPaymentScreen(
        orderId: orderId,
        invoiceId: invoice.invoiceId,
        invoiceUrl: invoice.invoiceUrl!,
        amount: amount,
        paymentMethod: method,
        serviceLabel: serviceLabel,
      ),
    ),
  );

  if (paid == true) {
    await _markPaymentPaid(orderId);
    return true;
  }

  await _markPaymentFailed(orderId);
  return false;
}

Future<void> _markPaymentPaid(int orderId) async {
  try {
    await getIt<OrderRemoteDataSource>().updateOrderStatus(
      id: orderId,
      paymentStatus: 'paid',
    );
  } catch (_) {}
}

Future<void> _markPaymentFailed(int orderId) async {
  try {
    await getIt<OrderRemoteDataSource>().updateOrderStatus(
      id: orderId,
      paymentStatus: 'failed',
    );
  } catch (_) {}
}

String bookingPaymentErrorMessage(Object error) =>
    ApiErrorMapper.message(
      error,
      fallbackEn: 'Payment could not be completed.',
      fallbackTl: 'Hindi natapos ang bayad.',
    );
