import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../data/data_source/order_remote_datasource.dart';
import '../../../domain/entities/transactions/transaction.dart';
import '../common/payment_status_badge.dart';
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

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;

    return Container(
      decoration:  BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surface(context, Colors.grey[300]!),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: widget.controller,
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${transaction.serviceName} — Order #${transaction.id}',
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.formatDate(transaction.date),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 13,
                    color: AppColors.foreground(context, Colors.grey[500]!),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                _detailRow(
                  Icons.circle,
                  Colors.green,
                  'Pickup',
                  transaction.pickupLocation,
                ),
                const SizedBox(height: 12),
                _detailRow(
                  Icons.circle,
                  Colors.red,
                  'Dropoff',
                  transaction.dropoffLocation,
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                if (transaction.items != null &&
                    transaction.items!.isNotEmpty) ...[
                  const Text(
                    'Items',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...transaction.items!.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.name}${item.unit != null ? ' (${item.unit})' : ''}',
                              style:  TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 14,
                                color: AppColors.foreground(context, Colors.black87),
                              ),
                            ),
                          ),
                          Text(
                            '${item.quantity}x',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 14,
                              color: AppColors.foreground(context, Colors.grey[600]!),
                            ),
                          ),
                          if (item.price != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'PHP ${(item.price! * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5F2D82),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                if (transaction.items != null &&
                    transaction.items!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final itemsTotal = transaction.items!.fold<double>(
                        0.0,
                        (sum, item) =>
                            sum + ((item.price ?? 0.0) * item.quantity),
                      );
                      final deliveryFee = transaction.amount - itemsTotal;

                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 14,
                                  color: AppColors.foreground(context, Colors.grey[600]!),
                                ),
                              ),
                              Text(
                                'PHP ${itemsTotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 14,
                                  color: AppColors.foreground(context, Colors.grey[600]!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (deliveryFee > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Delivery Fee',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: 14,
                                    color: AppColors.foreground(context, Colors.grey[600]!),
                                  ),
                                ),
                                Text(
                                  'PHP ${deliveryFee.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: 14,
                                    color: AppColors.foreground(context, Colors.grey[600]!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'PHP ${transaction.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5F2D82),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'PHP ${transaction.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5F2D82),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text(
                      'Order status',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 14,
                        color: AppColors.foreground(context, Colors.black54),
                      ),
                    ),
                    Text(
                      widget.statusLabel(transaction.rawStatus),
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: transaction.status == TransactionStatus.completed
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text(
                      'Payment',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 14,
                        color: AppColors.foreground(context, Colors.black54),
                      ),
                    ),
                    PaymentStatusBadge(status: transaction.paymentStatus),
                  ],
                ),
                if (transaction.paymentMethod != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text(
                        'Method',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 14,
                          color: AppColors.foreground(context, Colors.black54),
                        ),
                      ),
                      Text(
                        transaction.paymentMethod!,
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (_loadingProof) ...[
                  const SizedBox(height: 20),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ] else if (_proofImages.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ProofOfDeliverySection(imageUrls: _proofImages),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        widget.sharingReceipt ? null : widget.onDownloadReceipt,
                    icon: widget.sharingReceipt
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Download receipt (PDF)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent(context, Color(0xFF5F2D82)),
                      side: const BorderSide(color: Color(0xFF5F2D82)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    Color color,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 11,
                  color: AppColors.foreground(context, Colors.grey[500]!),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style:  TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 14,
                  color: AppColors.foreground(context, Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
