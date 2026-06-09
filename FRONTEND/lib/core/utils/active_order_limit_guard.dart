import 'package:flutter/material.dart';

import '../di/injection.dart';
import 'order_status_utils.dart';
import '../../data/data_source/order_remote_datasource.dart';

/// Limits how many non-terminal service orders a customer may have at once.
class ActiveOrderLimitGuard {
  ActiveOrderLimitGuard._();

  static const int maxActiveOrders = 3;

  static Future<int> fetchActiveOrderCount() async {
    final dataSource = getIt<OrderRemoteDataSource>();
    final response = await dataSource.getOrders(perPage: 30);
    if (!response.success) return 0;

    return response.data
        .where((order) => !OrderStatusUtils.isTerminal(order.status))
        .length;
  }

  /// Returns `true` when the customer may place another order.
  static Future<bool> ensureCanBook(BuildContext context) async {
    try {
      final count = await fetchActiveOrderCount();
      if (count < maxActiveOrders) return true;
      if (!context.mounted) return false;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Order limit reached'),
          content: Text(
            'You can only have up to $maxActiveOrders active service orders '
            'at a time. Please complete or cancel an existing order before '
            'placing a new one.\n\n'
            'Active orders: $count',
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    } catch (_) {
      // Do not block booking if the active-order check fails.
      return true;
    }
  }
}
