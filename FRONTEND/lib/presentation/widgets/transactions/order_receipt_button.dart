import 'package:flutter/material.dart';

import '../../../core/services/order_receipt_service.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../domain/entities/transactions/transaction.dart';

/// Downloads/shares a PDF receipt for a completed order.
class OrderReceiptButton extends StatefulWidget {
  const OrderReceiptButton({
    super.key,
    required this.orderId,
    required this.serviceName,
    this.serviceId = 3,
    this.amount = 0,
    this.pickupAddress = '',
    this.dropoffAddress = '',
    this.paymentMethod,
    this.paymentStatus = PaymentStatus.paid,
  });

  final String orderId;
  final String serviceName;
  final int serviceId;
  final double amount;
  final String pickupAddress;
  final String dropoffAddress;
  final String? paymentMethod;
  final PaymentStatus paymentStatus;

  @override
  State<OrderReceiptButton> createState() => _OrderReceiptButtonState();
}

class _OrderReceiptButtonState extends State<OrderReceiptButton> {
  bool _loading = false;

  Future<void> _download() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final tx = Transaction(
        id: widget.orderId,
        kind: TransactionKind.order,
        serviceName: widget.serviceName,
        serviceId: widget.serviceId,
        date: DateTime.now().toIso8601String(),
        pickupLocation: widget.pickupAddress,
        dropoffLocation: widget.dropoffAddress,
        amount: widget.amount,
        status: TransactionStatus.completed,
        rawStatus: 'completed',
        paymentStatus: widget.paymentStatus,
        paymentMethod: widget.paymentMethod,
      );
      await OrderReceiptService.shareTransactionReceipt(tx);
    } catch (_) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Could not generate receipt.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _download,
        icon: _loading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.purple.shade300,
                ),
              )
            : const Icon(Icons.picture_as_pdf_outlined),
        label: Text(
          'Download receipt (PDF)',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF5F2D82),
          side: const BorderSide(color: Color(0xFF5F2D82)),
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtils.spacing(context, 14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
