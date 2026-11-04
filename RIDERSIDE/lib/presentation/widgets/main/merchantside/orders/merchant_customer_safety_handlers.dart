import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../provider/main/merchantside/merchant_orders_provider.dart';
import '../../../chat/chat_report_sheet.dart';
import 'merchant_order_dialogs.dart';

/// Report or block the customer of an order (App Store Guideline 1.2).
/// Merchants have no chat with customers, so this hangs off the order.
class MerchantCustomerSafetyHandlers {
  MerchantCustomerSafetyHandlers._();

  /// What the menu on the order screen offers for a customer.
  static const reportLabel = 'Report customer';
  static String blockLabel(bool blocked) =>
      blocked ? 'Unblock customer' : 'Block customer';

  static Future<void> report(
    BuildContext context,
    WidgetRef ref, {
    required int orderId,
    required String customerLabel,
  }) async {
    final result = await ChatReportSheet.show(
      context,
      targetLabel: customerLabel,
      blockSubtitle: 'They will no longer be able to order from your store.',
    );
    if (result == null || !context.mounted) return;

    await _run(
      context,
      () => ref.read(merchantOrderActionProvider).reportCustomer(
            orderId,
            reason: result.reason,
            details: result.details,
            block: result.block,
          ),
      successMessage: result.block
          ? 'Thanks for reporting. The customer is blocked. Our team will review within 24 hours.'
          : 'Thanks for reporting. Our team will review within 24 hours.',
    );
  }

  static Future<void> setBlocked(
    BuildContext context,
    WidgetRef ref, {
    required int orderId,
    required bool block,
    required String customerLabel,
  }) async {
    if (block) {
      final confirm = await showMerchantConfirmDialog(
        context,
        title: 'Block this customer?',
        message:
            '$customerLabel will no longer be able to order from your store. '
            'You can unblock them from this screen at any time.',
        confirmLabel: 'Block',
      );
      if (!confirm || !context.mounted) return;
    }

    await _run(
      context,
      () => ref.read(merchantOrderActionProvider).setCustomerBlocked(orderId, block),
      successMessage: block ? 'Customer blocked.' : 'Customer unblocked.',
    );
  }

  static Future<void> _run(
    BuildContext context,
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
