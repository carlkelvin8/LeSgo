import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/merchant_order_amount_utils.dart';
import '../../data/data_source/dto/merchant/order_dto.dart';

class SalesReportService {
  SalesReportService._();

  static Future<void> shareCsv({
    required List<OrderDto> orders,
    required String periodLabel,
    required DateTime start,
    required DateTime end,
  }) async {
    final csv = _buildCsv(orders, periodLabel, start, end);
    final dir = await getTemporaryDirectory();
    final filename =
        'sales_report_${DateFormat('yyyyMMdd').format(start)}-${DateFormat('yyyyMMdd').format(end)}.csv';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Sales Report ($periodLabel)');
  }

  static Future<void> sharePdf({
    required List<OrderDto> orders,
    required String periodLabel,
    required DateTime start,
    required DateTime end,
  }) async {
    final bytes = await _buildPdf(orders, periodLabel, start, end);
    final filename =
        'sales_report_${DateFormat('yyyyMMdd').format(start)}-${DateFormat('yyyyMMdd').format(end)}.pdf';
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: filename,
    );
  }

  static String _buildCsv(
    List<OrderDto> orders,
    String periodLabel,
    DateTime start,
    DateTime end,
  ) {
    final buf = StringBuffer();

    final completed =
        orders.where((o) => MerchantOrderAmountUtils.isCompleted(o)).toList();
    final cancelled =
        orders.where((o) => MerchantOrderAmountUtils.isCancelled(o)).toList();
    final totalRevenue = completed.fold<double>(
      0,
      (sum, o) => sum + MerchantOrderAmountUtils.foodEarnings(o),
    );

    buf.writeln('Sales Report ($periodLabel)');
    buf.writeln(
        'Period,${DateFormat('MMM d, yyyy').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}');
    buf.writeln('Generated,${DateFormat('MMM d, yyyy h:mm a').format(DateTime.now())}');
    buf.writeln('');
    buf.writeln('Summary');
    buf.writeln('Total Orders,${orders.length}');
    buf.writeln('Completed,${completed.length}');
    buf.writeln('Cancelled,${cancelled.length}');
    buf.writeln('Total Revenue,PHP ${totalRevenue.toStringAsFixed(2)}');
    buf.writeln(
        'Avg Order Value,PHP ${completed.isNotEmpty ? (totalRevenue / completed.length).toStringAsFixed(2) : '0.00'}');
    buf.writeln('');
    buf.writeln(
        'Date,Reference,Items,Status,Payment Method,Item Total,Partner Share,Order Value');

    for (final order in orders) {
      final date = _formatDateCsv(order.createdAt);
      final ref = order.referenceNumber ?? '#${order.id}';
      final items = order.orderItems
              ?.map((i) => '${i.itemName} x${i.quantity}')
              .join('; ') ??
          '';
      final status = order.status;
      final payment = order.paymentMethod;
      final itemTotal = order.orderItems?.fold<double>(
              0, (s, i) => s + MerchantOrderAmountUtils.lineTotal(i)) ??
          0;
      final partnerShare = order.partnerShare ?? 0;
      final orderValue = MerchantOrderAmountUtils.foodEarnings(order);

      buf.writeln(
        '$date,$ref,"$items",$status,$payment,${itemTotal.toStringAsFixed(2)},${partnerShare.toStringAsFixed(2)},${orderValue.toStringAsFixed(2)}',
      );
    }

    return buf.toString();
  }

  static Future<List<int>> _buildPdf(
    List<OrderDto> orders,
    String periodLabel,
    DateTime start,
    DateTime end,
  ) async {
    final doc = pw.Document();

    final completed =
        orders.where((o) => MerchantOrderAmountUtils.isCompleted(o)).toList();
    final cancelled =
        orders.where((o) => MerchantOrderAmountUtils.isCancelled(o)).toList();
    final totalRevenue = completed.fold<double>(
      0,
      (sum, o) => sum + MerchantOrderAmountUtils.foodEarnings(o),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'LeSgo',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.purple700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Sales Report ($periodLabel)',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Period: ${DateFormat('MMM d, yyyy').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.Text(
                'Generated: ${DateFormat('MMM d, yyyy h:mm a').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          _summaryTable(context, orders.length, completed.length,
              cancelled.length, totalRevenue),
          pw.SizedBox(height: 24),
          pw.Text(
            'Order Details',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _orderTable(orders),
          pw.SizedBox(height: 24),
          pw.Text(
            'Thank you for using LeSgo.',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _summaryTable(
    pw.Context context,
    int total,
    int completed,
    int cancelled,
    double revenue,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _summaryRow('Total Orders', '$total'),
          _summaryRow('Completed', '$completed'),
          _summaryRow('Cancelled', '$cancelled'),
          pw.Divider(),
          _summaryRow('Total Revenue', 'PHP ${revenue.toStringAsFixed(2)}'),
          _summaryRow(
            'Avg Order Value',
            'PHP ${completed > 0 ? (revenue / completed).toStringAsFixed(2) : '0.00'}',
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _orderTable(List<OrderDto> orders) {
    final headers = ['Date', 'Reference', 'Items', 'Status', 'Amount'];
    final rows = orders.map((order) {
      final date = _formatDatePdf(order.createdAt);
      final ref = order.referenceNumber ?? '#${order.id}';
      final items = order.orderItems
              ?.map((i) => '${i.itemName} x${i.quantity}')
              .take(2)
              .join(', ') ??
          '';
      final status = order.status;
      final amount = MerchantOrderAmountUtils.foodEarnings(order);

      return [
        date,
        ref,
        items,
        status,
        'PHP ${amount.toStringAsFixed(2)}',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(
        color: PdfColors.purple700,
      ),
      cellStyle: pw.TextStyle(fontSize: 8),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.centerRight,
      },
      headers: headers,
      data: rows,
    );
  }

  static String _formatDateCsv(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return raw;
    return DateFormat('yyyy-MM-dd HH:mm').format(parsed);
  }

  static String _formatDatePdf(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return raw;
    return DateFormat('MM/dd HH:mm').format(parsed);
  }
}
