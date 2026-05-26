import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../di/injection.dart';
import '../utils/payment_status_utils.dart';
import '../../domain/entities/transactions/transaction.dart';
import '../../data/data_source/order_remote_datasource.dart';

/// Generates and shares PDF receipts for orders and LesPay top-ups.
class OrderReceiptService {
  OrderReceiptService._();

  static Future<void> shareTransactionReceipt(Transaction transaction) async {
    if (transaction.isOrder) {
      await _shareOrderReceipt(transaction);
    } else {
      await shareWalletReceipt(
        amount: transaction.amount,
        description: transaction.walletDescription ?? 'LesPay transaction',
        reference: transaction.walletReference ?? transaction.id,
        date: transaction.date,
        isCredit: transaction.isWalletCredit ?? true,
        paymentStatus: transaction.paymentStatus,
      );
    }
  }

  static Future<void> shareWalletReceipt({
    required double amount,
    required String description,
    required String reference,
    required String date,
    required bool isCredit,
    PaymentStatus paymentStatus = PaymentStatus.paid,
    double? feeAmount,
    double? totalCharged,
  }) async {
    final bytes = await _buildWalletPdf(
      amount: amount,
      description: description,
      reference: reference,
      date: date,
      isCredit: isCredit,
      paymentStatus: paymentStatus,
      feeAmount: feeAmount,
      totalCharged: totalCharged,
    );
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'lezgo-lespay-$reference.pdf',
    );
  }

  static Future<void> _shareOrderReceipt(Transaction transaction) async {
    Transaction enriched = transaction;
    final orderId = int.tryParse(transaction.id);
    if (orderId != null && orderId > 0) {
      try {
        final response =
            await getIt<OrderRemoteDataSource>().getOrderReceipt(orderId);
        if (response.success) {
          final o = response.data;
          enriched = Transaction(
            id: transaction.id,
            kind: transaction.kind,
            serviceName: transaction.serviceName,
            serviceId: transaction.serviceId,
            date: o.createdAt ?? transaction.date,
            pickupLocation: o.pickupAddress,
            dropoffLocation: o.dropoffAddress,
            amount: o.effectiveTotalAmount,
            status: transaction.status,
            rawStatus: o.status,
            paymentStatus:
                PaymentStatusUtils.fromOrderPaymentStatus(o.paymentStatus),
            paymentMethod: o.paymentMethod,
            items: transaction.items,
          );
        }
      } catch (e) {
        debugPrint('Receipt API fallback to local data: $e');
      }
    }

    final bytes = await _buildOrderPdf(enriched);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'lezgo-receipt-${enriched.id}.pdf',
    );
  }

  static Future<List<int>> _buildOrderPdf(Transaction tx) async {
    final doc = pw.Document();
    final formattedDate = _formatDate(tx.date);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _header(),
          pw.SizedBox(height: 16),
          pw.Text(
            'Official Receipt',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Order #${tx.id}'),
          pw.Text('Service: ${tx.serviceName}'),
          pw.Text('Date: $formattedDate'),
          if (tx.paymentMethod != null)
            pw.Text('Payment: ${tx.paymentMethod}'),
          pw.Text(
            'Payment status: ${PaymentStatusUtils.label(tx.paymentStatus)}',
          ),
          pw.Divider(),
          if (tx.pickupLocation.isNotEmpty) ...[
            pw.Text('Pickup', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(tx.pickupLocation),
            pw.SizedBox(height: 8),
          ],
          if (tx.dropoffLocation.isNotEmpty) ...[
            pw.Text('Dropoff', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(tx.dropoffLocation),
            pw.SizedBox(height: 8),
          ],
          if (tx.items != null && tx.items!.isNotEmpty) ...[
            pw.Text('Items', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            ...tx.items!.map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        '${item.name} x${item.quantity}',
                      ),
                    ),
                    pw.Text(
                      'PHP ${((item.price ?? 0) * item.quantity).toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 8),
          ],
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TOTAL',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'PHP ${tx.amount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Thank you for using LEZGO.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
    return doc.save();
  }

  static Future<List<int>> _buildWalletPdf({
    required double amount,
    required String description,
    required String reference,
    required String date,
    required bool isCredit,
    required PaymentStatus paymentStatus,
    double? feeAmount,
    double? totalCharged,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(),
            pw.SizedBox(height: 16),
            pw.Text(
              'LesPay ${isCredit ? 'Top-up' : 'Payment'} Receipt',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Reference: $reference'),
            pw.Text('Date: ${_formatDate(date)}'),
            pw.Text(
              'Status: ${PaymentStatusUtils.label(paymentStatus)}',
            ),
            pw.Divider(),
            pw.Text(description),
            if (feeAmount != null && feeAmount > 0) ...[
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Wallet credit'),
                  pw.Text('PHP ${amount.toStringAsFixed(2)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Service fee (3%)'),
                  pw.Text('PHP ${feeAmount.toStringAsFixed(2)}'),
                ],
              ),
              if (totalCharged != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total paid', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      'PHP ${totalCharged.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
            ] else
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    isCredit ? 'Amount credited' : 'Amount debited',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    '${isCredit ? '+' : '-'}PHP ${amount.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            pw.Spacer(),
            pw.Text(
              'This is your LesPay wallet transaction record.',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  static pw.Widget _header() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'LEZGO',
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF5F2D82),
          ),
        ),
        pw.Text(
          'Cagayan de Oro, Philippines',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
