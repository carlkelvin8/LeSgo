import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/data_source/dto/merchant/order_dto.dart';
import 'merchant_order_amount_utils.dart';

/// Utility to export merchant orders to CSV and share the file.
class MerchantCsvExportUtils {
  /// Generates a CSV file from orders and triggers the share sheet.
  static Future<void> exportAndShare(
    BuildContext context,
    List<OrderDto> orders,
  ) async {
    if (orders.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No orders to export')),
        );
      }
      return;
    }

    final csv = _generateCsv(orders);
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final fileName = 'orders_export_$dateStr.csv';

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Orders Export - $dateStr',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  static String _generateCsv(List<OrderDto> orders) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln(
      'Order ID,Date,Customer,Items,Subtotal,Delivery Fee,Total,Status,Payment Method',
    );

    for (final order in orders) {
      final orderId = order.referenceNumber ?? order.id.toString();
      final date = _formatDate(order.createdAt);
      final customer = _escapeCsv(order.user?.name ?? 'Unknown');
      final items = _escapeCsv(
        order.orderItems?.map((i) => '${i.quantity}x ${i.itemName}').join('; ') ??
            'N/A',
      );

      double subtotal = 0;
      if (order.orderItems != null) {
        for (final item in order.orderItems!) {
          subtotal += MerchantOrderAmountUtils.lineTotal(item);
        }
      }

      final deliveryFee =
          order.totalFare ?? order.estimatedFare ?? order.distanceFare ?? 0.0;
      final total = subtotal + deliveryFee;
      final status = order.status;
      final paymentMethod = order.paymentMethod;

      buffer.writeln(
        '$orderId,$date,$customer,$items,${subtotal.toStringAsFixed(2)},${deliveryFee.toStringAsFixed(2)},${total.toStringAsFixed(2)},$status,$paymentMethod',
      );
    }

    return buffer.toString();
  }

  static String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (_) {
      return raw;
    }
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
