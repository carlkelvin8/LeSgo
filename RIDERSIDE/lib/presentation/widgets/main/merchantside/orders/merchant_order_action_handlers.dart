import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/merchant_order_ops_utils.dart';
import '../../../../provider/main/merchantside/merchant_orders_provider.dart';
import 'merchant_order_dialogs.dart';

class MerchantOrderActionHandlers {
  MerchantOrderActionHandlers._();

  static Future<void> accept(
    BuildContext context,
    WidgetRef ref, {
    required int orderId,
    VoidCallback? onSuccess,
  }) async {
    final confirm = await showMerchantConfirmDialog(
      context,
      title: 'Accept Order?',
      message: 'This will accept the order and start the 15-minute prep timer.',
      confirmLabel: 'Accept',
    );
    if (!confirm || !context.mounted) return;

    await _run(
      context,
      () => ref.read(merchantOrderActionProvider).acceptOrder(orderId),
      successMessage: 'Order accepted successfully!',
      onSuccess: onSuccess,
    );
  }

  static Future<void> reject(
    BuildContext context,
    WidgetRef ref, {
    required int orderId,
    VoidCallback? onSuccess,
  }) async {
    if (!context.mounted) return;

    final reason = await showMerchantCancelReasonDialog(
      context,
      title: 'Reject Order',
      hint: 'Reason for rejecting this order',
    );
    if (reason == null || !context.mounted) return;

    await _run(
      context,
      () => ref.read(merchantOrderActionProvider).rejectOrder(orderId, reason),
      successMessage: 'Order rejected.',
      onSuccess: onSuccess,
    );
  }

  static Future<void> cancelAfterAccept(
    BuildContext context,
    WidgetRef ref, {
    required int orderId,
    VoidCallback? onSuccess,
  }) async {
    if (!context.mounted) return;

    final reason = await showMerchantCancelReasonDialog(
      context,
      title: 'Cancel Order',
      hint: 'Reason for cancelling this order',
    );
    if (reason == null || !context.mounted) return;

    await _run(
      context,
      () => ref.read(merchantOrderActionProvider).cancelOrder(orderId, reason),
      successMessage: 'Order cancelled.',
      onSuccess: onSuccess,
    );
  }

  static Future<void> handleStatusLongPress(
    BuildContext context,
    WidgetRef ref, {
    required String status,
    required int orderId,
    VoidCallback? onSuccess,
  }) async {
    if (MerchantOrderOpsUtils.canReject(status)) {
      await reject(context, ref, orderId: orderId, onSuccess: onSuccess);
      return;
    }

    if (MerchantOrderOpsUtils.canCancelAfterAccept(status)) {
      await cancelAfterAccept(context, ref, orderId: orderId, onSuccess: onSuccess);
    }
  }

  static Future<void> _run(
    BuildContext context,
    Future<void> Function() action, {
    required String successMessage,
    VoidCallback? onSuccess,
  }) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updating order...')),
      );
      await action();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      onSuccess?.call();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e')),
      );
    }
  }
}
