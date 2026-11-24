import 'package:lesgo/core/utils/money.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../data/data_source/order_remote_datasource.dart';
import '../../../domain/entities/transactions/transaction.dart';
import '../orders/order_style.dart';
import '../orders/premium_order_widgets.dart';
import '../orders/proof_of_delivery_section.dart';

class OrderTransactionDetailSheet extends StatefulWidget {
  final Transaction transaction;
  final ScrollController controller;
  final String Function(String) formatDate;
  final String Function(String) statusLabel;
  final bool sharingReceipt;
  final VoidCallback onDownloadReceipt;

  const OrderTransactionDetailSheet({
    super.key,
    required this.transaction,
    required this.controller,
    required this.formatDate,
    required this.statusLabel,
    required this.sharingReceipt,
    required this.onDownloadReceipt,
  });

  @override
  State<OrderTransactionDetailSheet> createState() =>
      _OrderTransactionDetailSheetState();
}

class _OrderTransactionDetailSheetState
    extends State<OrderTransactionDetailSheet> {
  List<String> _proofImages = [];
  bool _loadingProof = false;

  @override
  void initState() {
    super.initState();
    _proofImages = widget.transaction.proofImages;
    _loadProofImages();
  }

  Future<void> _loadProofImages() async {
    final orderId = int.tryParse(widget.transaction.id);
    if (orderId == null) return;

    setState(() => _loadingProof = true);
    try {
      final dataSource = getIt<OrderRemoteDataSource>();
      var proofs = await dataSource.fetchProofImages(orderId);

      if (proofs.isEmpty) {
        try {
          final response = await dataSource.getOrder(orderId);
          proofs = response.data.proofImages;
        } catch (e) {
          debugPrint('Order DTO fallback failed for order $orderId: $e');
        }
      }

      if (!mounted) return;
      if (proofs.isNotEmpty) {
        setState(() => _proofImages = proofs);
      }
    } catch (e) {
      debugPrint('Failed to load proof images for order $orderId: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingProof = false);
      }
    }
  }

  /// What the payment actually is, in words that make sense: a cancelled order
  /// that was never charged says so instead of "Pending".
  ({String text, Color color}) _payment(Transaction t) {
    switch (t.paymentStatus) {
      case PaymentStatus.paid:
        return (text: 'Paid', color: const Color(0xFF2E9E5B));
      case PaymentStatus.refunded:
        return (text: 'Refunded', color: const Color(0xFF1E88E5));
      case PaymentStatus.failed:
        return (text: 'Failed', color: const Color(0xFFE5484D));
      case PaymentStatus.pending:
        return t.status == TransactionStatus.cancelled
            ? (text: 'Not charged', color: Colors.grey)
            : (text: 'Pending', color: const Color(0xFFEF8A1B));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final cancelled = t.status == TransactionStatus.cancelled;
    final done = t.status == TransactionStatus.completed;
    final statusLabel = done
        ? 'Completed'
        : (cancelled ? 'Cancelled' : widget.statusLabel(t.rawStatus));
    final pay = _payment(t);
    final items = t.items ?? const <TransactionItem>[];
    final itemsTotal = items.fold<double>(
      0.0,
      (sum, i) => sum + ((i.price ?? 0.0) * i.quantity),
    );
    final deliveryFee = t.amount - itemsTotal;
    final food = t.serviceName == 'LesEat' || t.serviceName == 'LesBuy';
    final failed = t.paymentStatus == PaymentStatus.failed;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(context, Colors.grey[300]!),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: widget.controller,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // Who / when / how it ended. No database ids.
                Reveal(
                  child: OrderStatusHeader(
                    service: t.serviceName,
                    date: widget.formatDate(t.date),
                    statusLabel: statusLabel,
                    tone: (cancelled || failed)
                        ? HeroTone.danger
                        : done
                        ? HeroTone.success
                        : HeroTone.active,
                    caption: cancelled
                        ? 'Order total ${Money.format(t.amount)} · ${pay.text}'
                        : pay.text,
                  ),
                ),
                const SizedBox(height: 28),
                if (t.pickupLocation.trim().isNotEmpty ||
                    t.dropoffLocation.trim().isNotEmpty) ...[
                  Reveal(
                    index: 1,
                    child: RouteCard(
                      flat: true,
                      pickup: t.pickupLocation,
                      dropoff: t.dropoffLocation,
                      pickupLabel: food ? 'Restaurant' : 'Pickup',
                      dropoffLabel: food ? 'Deliver to' : 'Drop-off',
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
                Reveal(
                  index: 2,
                  child: ReceiptCard(
                    flat: true,
                    items: [
                      for (final item in items)
                        ReceiptItem(
                          qty: item.quantity,
                          name:
                              '${item.name}${item.unit != null ? ' (${item.unit})' : ''}',
                          price: item.price == null
                              ? null
                              : Money.format(item.price! * item.quantity),
                        ),
                    ],
                    rows: [
                      if (items.isNotEmpty) ...[
                        ReceiptRow('Subtotal', Money.format(itemsTotal)),
                        if (deliveryFee > 0)
                          ReceiptRow('Delivery fee', Money.format(deliveryFee)),
                      ],
                    ],
                    total: Money.format(t.amount),
                    totalLabel: cancelled ? 'Order total' : 'Total',
                    footer: PaymentStrip(
                      method: t.paymentMethod == null
                          ? 'Payment'
                          : OrderStyle.paymentMethodLabel(t.paymentMethod),
                      status: pay.text,
                      statusColor: pay.color,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                if (_loadingProof)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_proofImages.isNotEmpty) ...[
                  ProofOfDeliverySection(imageUrls: _proofImages),
                  const SizedBox(height: 28),
                ],
                PremiumButton(
                  flat: true,
                  label: 'Download receipt (PDF)',
                  icon: Icons.picture_as_pdf_outlined,
                  loading: widget.sharingReceipt,
                  onPressed: widget.onDownloadReceipt,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
